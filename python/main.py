import functools
import sys
from typing import Union, Optional
from pyotherside import send as qsend
from pathlib import Path

script_path = Path(__file__).absolute().parent # /usr/share/harbour-saildiscord/python
sys.path.insert(0, str(script_path.parent / 'lib/deps')) # /usr/share/harbour-saildiscord/lib/deps

while True:
    try:
        from utils import *
        from providers import Provider, ProviderMapping
        break
    except: pass

from utils import convert_tool

api: Optional[Provider] = None
tools: List[dict] = []
no_content: bool = False

def api_required(func):
    @functools.wraps(func)
    def f(*args, **kwargs):
        if api:
            func(*args, **kwargs)
    return f

def set_settings(proxy, no_content, provider, settings: dict) -> bool:
    global api
    provider = ProviderMapping(provider)
    if not provider.implementation or provider.name not in settings:
        return False
    
    settings = settings[provider.name]
    api = provider.implementation(proxy=convert_proxy(proxy), no_content=no_content, api_key=settings.pop('key', settings.pop('api_key', None)), **settings)
    return True

def request_models():
    if not api:
        return
    for m in api.models:
        qsend('model', m)

@api_required
def chat(model, history=[], use_tools=False):
    qsend('chat_start')
    try:
        for chunk in api.chat(model, history, tools if use_tools else None):
            qsend(f'chunk{model}', chunk)
    finally:
        qsend('chat_end')

def register_tool(*args):
    tools.append(convert_tool(*args))