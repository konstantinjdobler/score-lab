print(
    "Empty docker run command. docker run received no command arguments / script to run. Please specifiy like this: docker run <options> <my-command>. This is a custom warning."
)

import torch

print("torch availability check: ", torch.cuda.is_available())
