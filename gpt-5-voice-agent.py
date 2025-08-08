# export OPENAI_API_KEY=sk_proj-...
# uv run gpt-5-voice-agent.py

# /// script
# dependencies = [
#   "numba==0.61.2",
#   "openai==1.99.1",
#   "python-dotenv",
#   "fastapi[all]",
#   "uvicorn",
#   "pipecat-ai[silero,webrtc,openai]",
#   "pipecat-ai-small-webrtc-prebuilt",
# ]
# ///


import os
from datetime import datetime

from dotenv import load_dotenv
from loguru import logger

from pipecat.audio.vad.silero import SileroVADAnalyzer
from pipecat.pipeline.pipeline import Pipeline
from pipecat.pipeline.runner import PipelineRunner
from pipecat.pipeline.task import PipelineParams, PipelineTask
from pipecat.processors.aggregators.openai_llm_context import OpenAILLMContext
from pipecat.processors.aggregators.llm_response import LLMUserAggregatorParams
from pipecat.runner.types import RunnerArguments
from pipecat.runner.utils import create_transport
from pipecat.services.openai.base_llm import BaseOpenAILLMService
from pipecat.services.openai.llm import OpenAILLMService
from pipecat.services.openai.tts import OpenAITTSService
from pipecat.services.openai.stt import OpenAISTTService
from pipecat.transports.base_transport import BaseTransport, TransportParams
from pipecat.processors.frameworks.rtvi import (
    RTVIConfig,
    RTVIObserver,
    RTVIProcessor,
)
from pipecat.frames.frames import (
    Frame,
    VisionImageRawFrame,
    UserImageRawFrame,
    UserImageRequestFrame,
)
from pipecat.processors.frame_processor import FrameDirection, FrameProcessor
from pipecat.services.llm_service import FunctionCallParams
from pipecat.adapters.schemas.function_schema import FunctionSchema
from pipecat.adapters.schemas.tools_schema import ToolsSchema
from pipecat.runner.utils import get_transport_client_id

load_dotenv(override=True)

SYSTEM_INSTRUCTION = f"""
# DATE
The current date is {datetime.now().strftime("%Y-%m-%d")}.

# ROLE AND BEHAVIOR
You are a helpful LLM in a voice conversation.

You are receiving transcribed text. Automatically correct for likely transcription errors. Infer what the user said even if the transcription is wrong or incomplete.

Your output will be converted to audio so don't include special characters in your answers. Use plain text sentences. Keep your sentences short. Keep your responses brief. Respond with a single sentence unless a longer answer is specifically appropriate to the user's question.

# VIDEO STREAM CAPABILITY

You have access to a tool called "queue_for_image_description".

Call the queue_for_image_description function when a user asks a question about the video stream. When this function returns, do not generate any text. Respond with an empty string. An image from the video stream will be provided asynchronously for future processing. 

The user may refer to the video stream as the video, the camera, the stream, or say something general like "what can you see?" Whenever the user expresses an interest in something visual and realtime, they are probably talking about this video stream capability.
"""

# We store functions so objects (e.g. SileroVADAnalyzer) don't get
# instantiated. The function will be called when the desired transport gets
# selected.
transport_params = {
    "webrtc": lambda: TransportParams(
        audio_in_enabled=True,
        video_in_enabled=True,
        audio_out_enabled=True,
        vad_analyzer=SileroVADAnalyzer(),
    ),
}


async def queue_for_image_description(params: FunctionCallParams):
    await params.llm.image_query_processor.request_image_frame(params.arguments["question"])
    await params.result_callback(
        {"result": "success", "llm_response": "Do not respond. Wait for next turn."}
    )


queue_for_image_description_schema = FunctionSchema(
    name="queue_for_image_description",
    description="Asynchronously request an image from the video camera. Call this function when a user asks a question about the video stream. When this function returns, do not generate any text. Respond with an empty string. Wait for the next turn.",
    properties={
        "question": {
            "type": "string",
            "description": "The question the user asked.",
        }
    },
    required=["question"],
)
tools = ToolsSchema(standard_tools=[queue_for_image_description_schema])


class ImageQueryProcessor(FrameProcessor):
    """Any time we see an InputImageRawFrame, attach the most recent query text from the LLM tool call."""

    def __init__(self):
        super().__init__()
        self.participant_id = None
        self._describe_text = None

    async def request_image_frame(self, question: str):
        await self.push_frame(
            UserImageRequestFrame(self.participant_id),
            direction=FrameDirection.UPSTREAM,
        )
        self._describe_text = question

    async def process_frame(self, frame: Frame, direction: FrameDirection):
        await super().process_frame(frame, direction)

        if isinstance(frame, UserImageRawFrame):
            if self._describe_text:
                frame = VisionImageRawFrame(
                    text=self._describe_text,
                    image=frame.image,
                    size=frame.size,
                    format=frame.format,
                )
                await self.push_frame(frame)
                self._describe_text = None
        else:
            await self.push_frame(frame, direction)


async def run_bot(transport: BaseTransport, runner_args: RunnerArguments):
    logger.info("Starting bot")

    stt = OpenAISTTService(api_key=os.getenv("OPENAI_API_KEY"))

    tts = OpenAITTSService(api_key=os.getenv("OPENAI_API_KEY"))

    image_query_processor = ImageQueryProcessor()

    llm = OpenAILLMService(
        api_key=os.getenv("OPENAI_API_KEY"),
        model="gpt-5-mini",
        params=BaseOpenAILLMService.InputParams(
            extra={
                "service_tier": "priority",
                "reasoning_effort": "minimal",
                # "verbosity": "low",
            },
        ),
    )
    llm.register_function("queue_for_image_description", queue_for_image_description)
    llm.image_query_processor = image_query_processor

    rtvi = RTVIProcessor(config=RTVIConfig(config=[]))

    messages = [
        {
            "role": "system",
            "content": SYSTEM_INSTRUCTION,
        },
    ]

    context = OpenAILLMContext(messages, tools)
    context_aggregator = llm.create_context_aggregator(
        context,
        user_params=LLMUserAggregatorParams(aggregation_timeout=0.0),
    )

    pipeline = Pipeline(
        [
            transport.input(),  # Transport user input
            image_query_processor,
            rtvi,
            stt,
            context_aggregator.user(),  # User responses
            llm,  # LLM
            tts,  # TTS
            transport.output(),  # Transport bot output
            context_aggregator.assistant(),  # Assistant spoken responses
        ]
    )

    task = PipelineTask(
        pipeline,
        params=PipelineParams(
            enable_metrics=True,
            enable_usage_metrics=True,
        ),
        observers=[RTVIObserver(rtvi)],
    )

    @transport.event_handler("on_client_connected")
    async def on_client_connected(transport, client):
        logger.info("Client connected")

        participant_id = get_transport_client_id(transport, client)
        image_query_processor.participant_id = participant_id

        # Kick off the conversation.
        messages.append({"role": "system", "content": "Please introduce yourself to the user."})
        await task.queue_frames([context_aggregator.user().get_context_frame()])

    @transport.event_handler("on_client_disconnected")
    async def on_client_disconnected(transport, client):
        logger.info("Client disconnected")
        await task.cancel()

    runner = PipelineRunner(handle_sigint=runner_args.handle_sigint)

    await runner.run(task)


async def bot(runner_args: RunnerArguments):
    """Main bot entry point compatible with Pipecat Cloud."""
    transport = await create_transport(runner_args, transport_params)
    await run_bot(transport, runner_args)


if __name__ == "__main__":
    from pipecat.runner.run import main

    main()