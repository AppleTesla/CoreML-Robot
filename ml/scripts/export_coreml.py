"""
Convert external models (e.g., YOLO, PyTorch) to CoreML format.

Usage:
    python export_coreml.py --model yolov8n.pt --output ObjectDetector.mlmodel

Requires: pip install coremltools ultralytics
"""

import argparse
from pathlib import Path


def export_yolo_to_coreml(model_path: str, output_path: str):
    """Export a YOLO model to CoreML format."""
    try:
        from ultralytics import YOLO
    except ImportError:
        print("Install ultralytics: pip install ultralytics")
        return

    model = YOLO(model_path)
    model.export(format="coreml", nms=True, imgsz=640)
    print(f"Exported to CoreML: {output_path}")


def export_pytorch_to_coreml(model_path: str, output_path: str):
    """Export a PyTorch model to CoreML format using coremltools."""
    try:
        import torch
        import coremltools as ct
    except ImportError:
        print("Install: pip install torch coremltools")
        return

    model = torch.load(model_path, map_location="cpu")
    model.eval()

    # Trace the model
    example_input = torch.randn(1, 3, 640, 640)
    traced = torch.jit.trace(model, example_input)

    # Convert to CoreML
    mlmodel = ct.convert(
        traced,
        inputs=[ct.ImageType(name="image", shape=example_input.shape, scale=1/255.0)],
    )
    mlmodel.save(output_path)
    print(f"Exported to CoreML: {output_path}")


def main():
    parser = argparse.ArgumentParser(description="Export models to CoreML format")
    parser.add_argument("--model", required=True, help="Path to source model")
    parser.add_argument("--output", default="ObjectDetector.mlmodel", help="Output .mlmodel path")
    parser.add_argument("--format", choices=["yolo", "pytorch"], default="yolo", help="Source model format")
    args = parser.parse_args()

    if args.format == "yolo":
        export_yolo_to_coreml(args.model, args.output)
    elif args.format == "pytorch":
        export_pytorch_to_coreml(args.model, args.output)


if __name__ == "__main__":
    main()
