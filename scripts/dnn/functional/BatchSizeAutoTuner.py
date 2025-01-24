# Example usage:
import gc
from typing import Sequence

import torch
from torchvision.models import resnet50


def get_free_memory(device_id=0):
    # 获取显存信息
    torch.cuda.set_device(device_id)
    allocated = torch.cuda.memory_allocated(device_id)  # 已分配的显存
    reserved = torch.cuda.memory_reserved(device_id)  # 已保留的显存
    total_memory = torch.cuda.get_device_properties(device_id).total_memory  # 总显存
    free_memory = total_memory - allocated - reserved  # 空闲显存
    return free_memory, total_memory


def find_max_batch_size(
    model: torch.nn.Module,
    device: int | str | torch.device,
    input_shape: Sequence = (3, 224, 224),
    max_memory_frac: float = 0.8,
) -> int:
    """
    从 batch size = 1 开始，以指数方式寻找最大可用 batch size。
    :param model: PyTorch 模型
    :param device: 计算设备，通常是 'cuda' 或 'cpu'
    :param input_shape: 单个样本的形状，默认 (3, 224, 224)
    :param max_memory_frac: 显存使用的最大比例 (0~1)，默认为0.9
    :return: 最大可用 batch size
    """
    torch.cuda.set_per_process_memory_fraction(max_memory_frac, device=device)
    model.to(device)
    batch_size = 1  # 起始 batch size
    max_batch_size = 0  # 记录最大成功的 batch size

    while True:
        try:
            # 创建输入张量
            example_input = torch.randn(batch_size, *input_shape).to(device)
            with torch.no_grad():
                output = model(example_input)  # 前向推理
            max_batch_size = batch_size  # 更新最大成功的 batch size
            print(f"Batch size {batch_size} succeeded.")

            # 删除临时变量，释放显存
            del example_input, output
            torch.cuda.empty_cache()  # 清理未使用的显存
            gc.collect()  # 强制垃圾回收

            # 指数增加 batch size
            batch_size *= 2

        except RuntimeError as e:
            # 捕获 OOM 错误
            if "out of memory" in str(e):
                print(f"Out of memory with batch size {batch_size}.")
                break
            else:
                raise e  # 其他错误抛出

    return max_batch_size


if __name__ == "__main__":
    free_memory, total_memory = get_free_memory()
    print(f"Free Memory: {free_memory / 1e9} GB")
    print(f"Total Memory: {total_memory / 1e9} GB")
    model = resnet50()  # 示例模型
    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
    batch_size = find_max_batch_size(model, device)
    print(f"Recommended batch size: {batch_size}")
