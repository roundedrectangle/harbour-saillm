# SaiLLM

Sai(lfish) Large Language Models

right now lots of stuff is broken. ollama and openai/chatgpt backends are supported at the moment. only default set of tools is available, which only includes flashlight for now.

you NEED to setup a backend for this to work

open ai instructions: register as chat gpt developer and gather an api key, go to settings, set backend as openai and api key as api key. if you don't know what base url means you should not touch it probably

ollama instructions:

1. download ollama to your computer with the script they provide here https://ollama.com/download
2. run `sudo systemctl edit ollama`, or `sudo SYSTEMD_EDITOR=editor systemctl edit ollama` replacing editor with your favourite text editor
3. in the opened editor add the following between these comments
    ```ini
    ### Editing /etc/systemd/system/ollama.service.d/override.conf
    ### Anything between here and the comment below will become the contents of the drop-in file

    [Service]
    Environment="OLLAMA_HOST=0.0.0.0"
    Environment="OLLAMA_ORIGINS=*"
    Environment="OLLAMA_NUM_PARALLEL=1"

    ### Edits below this comment will be discarded
    ```
4. save file and close the editor
5. `sudo systemctl restart ollama`
6. open app, go to settings, set backend as ollama
7. as host set "http://x.x.x.x:11434", replacing x.x.x.x with your computer's IP address/hostname (if you're using local IP/hostname your phone will need to be on the same network as computer)

i guess that's it