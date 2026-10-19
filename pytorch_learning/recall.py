import torch

device = torch.device('cuda')

# tensor = torch.tensor([0, 1, 2, 3], device=device)

# print(f'Tensor is stored on: {tensor.device}')

# print(f'Last Value: {tensor[-1]}')
# print(f'Everything except last 2 values {tensor[:-2]}')

# tensor_row2 = torch.tensor([4, 5, 6, 7], device=device)

# full_tensor = torch.cat([tensor,tensor_row2], dim=-1)
# print(f'I\'m a concatinated full tensor:{full_tensor}')

# full_tensor = torch.stack([tensor,tensor_row2], dim=0)
# print(f'I\'m a stacked full tensor:{full_tensor}')

mat1 = torch.tensor([[0, 1],
                     [1, 0]])

mat2 = torch.tensor([[-1, 0],
                  [0, -1]])

result = mat1 @ mat2
print(result)