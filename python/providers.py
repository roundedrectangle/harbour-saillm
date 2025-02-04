# pyright: reportImplicitOverride=false
from openai.types.chat import ChatCompletionChunk
from pyotherside import send as qsend
from provider_abc import Provider
from utils import *
from enum import Enum
from typing import Optional, Type
from openai import OpenAI
from ollama import Client as Ollama
import ollama._types, httpx

__all__ = ['Provider', 'ProviderMapping', 'OpenAIProvider', 'OllamaProvider']

class ProviderMapping(Enum):
    unset = 0
    ollama = 1
    openai = 2

    @property
    def implementation(self) -> Optional[Type[Provider]]:
        if self == ProviderMapping.ollama:
            return OllamaProvider
        if self == ProviderMapping.openai:
            return OpenAIProvider

class OpenAIProvider(Provider):
    def __init__(self, **kwargs):
        proxy = kwargs.pop('proxy', None)
        self.client = OpenAI(
            http_client=httpx.Client(proxy=proxy) if proxy else None,
            base_url=kwargs.pop('base_url', kwargs.pop('host', None)) or None,
            **kwargs
        )

    @property
    def models(self):
        for m in self.client.models.list():
            yield m.id
    
    def chat(self, model, history=[], tools=[]):
        qsend(str(tools))
        for chunk in self.client.chat.completions.create(model=model, messages=convert_history(history), tools=tools or None, stream=True):
            chunk: ChatCompletionChunk
            d = chunk.choices[0].delta
            for tool in d.tool_calls or []:
                if tool.function:
                    if tool.function.arguments:
                        qsend('toolArguments', str(tool.function.arguments))
                    qsend(f'toolcall__{tool.function.name}')
            yield d.content or '*No content*'

# def toggle_flashlight(mode: str) -> None:
#     """
#     Toggles flashlight

#     Args:
#       mode: If "on", toggle flashlight on; if "off", toggle flashlight off
    
#     Returns:
#       None
#     """
#     if mode in ('on', 'off'):
#         qsend('toggle_flashlight', mode == 'on')
#     else:
#         qsend('flashlightError', type(mode).__name__, str(mode))

class OllamaProvider(Provider):
    def __init__(self, **kwargs):
        kwargs.pop('api_key', None)
        self.client = Ollama(
            kwargs.pop('base_url', kwargs.pop('host', None)) or None,
            proxy=kwargs.pop('proxy', None) or None,
            **kwargs
        )

    @property
    def models(self):
        for m in self.client.list().models:
            if m.model is not None:
                yield m.model
    
    def chat(self, model, history=[], tools=[]):
        qsend(str(tools))
        try:
            for chunk in self.client.chat(model, convert_history(history), tools=tools or None, stream=True):
                for tool in chunk.message.tool_calls or []:
                    # if tool.function.name == 'toggle_flashlight':
                    #     args = dict(tool.function.arguments)
                    #     if 'mode' in args:
                    #         toggle_flashlight(args.pop('mode'))
                    #     else:
                    #         qsend('flashlightNothingError')
                    #     if args:
                    #         qsend('flashlightExtraError', repr(args))
                    if tool.function.arguments:
                        qsend('toolArguments', str(tool.function.arguments))
                    qsend(f'toolcall__{tool.function.name}')
                if chunk.message.content:
                    yield chunk.message.content or '*No content*'
        except ollama._types.ResponseError as e:
            if 'does not support tools' in e.error:
                qsend("toolsError", model)
                yield '*Tools unsupported*'
            else:
                raise e