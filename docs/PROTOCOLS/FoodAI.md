Gemini said
For image processing tasks specifically focused on food—where you need to recognize ingredients, cooking styles, or estimate calories—you need a Vision Language Model (VLM) that is small enough to run on-device (mobile/edge) or with minimal server costs.

As of 2026, the following models are the top recommendations for "small but powerful" food image description.

1. Top Small Models (The "Nano" Class)
These models are designed specifically for efficiency and can often run on a modern smartphone or a basic laptop GPU.

Moondream2 / Moondream3
Size: ~1.6B parameters.

Why it’s good for food: It is exceptionally "tiny" and excels at short, descriptive captions. It can identify objects (like "grilled salmon" or "broccoli") with very low latency.

Best for: Real-time mobile apps where speed is more important than deep nutritional reasoning.

SmolVLM (Hugging Face)
Size: Available in 256M to 2.2B parameters.

Why it’s good for food: The 256M version is one of the smallest multimodal models in existence. It uses very little VRAM (less than 1GB), making it perfect for hyper-efficient "what is this food?" tagging.

PaliGemma 2 (Google)
Size: Starts at 3B parameters.

Why it’s good for food: This is a "mix" model optimized for fine-tuning. Because it’s built on Google’s Gemma, it has a strong understanding of diverse cuisines and can be prompted to "detect food; plate; bowl" to help with portion size estimation.