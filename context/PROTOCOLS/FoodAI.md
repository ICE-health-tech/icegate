# Food AI protocol

Vision-language analysis for meal photos: identify food, estimate portions, and return macronutrients for the Icegate health flow.

## Architecture

| Layer | Responsibility |
|--------|----------------|
| **Flutter app** | Uploads meal image to S3 (public HTTPS URL), calls the food agent HTTP API, parses calories/macros. See `lib/orchestration_layer/Services/Health/AIFoodCaloriesServices.dart` and `FoodAnalysisBlock`. |
| **Food agent (HTTP service)** | Loads the image from `s3_url`, runs the VLM + any tools (volume/calorie math), returns JSON the app understands. Configured with `FOOD_AGENT_URL` in `.env` (see `.env.example`). |

**Default in this repo:** the app talks to the HTTP agent only—no on-device model code ships here yet.

### Optional: small Gemma on the phone (edge)

Google publishes **edge-oriented Gemma 4** sizes (e.g. **E2B / E4B** “effective” parameter scales) for devices that can host a local model. Official starting points:

| Piece | Role |
|-------|------|
| **[Deploy Gemma on mobile](https://ai.google.dev/gemma/docs/integrations/mobile)** | Overview: AI Edge Gallery app for testing, MediaPipe **LLM Inference** on **Android** and **iOS**. |
| **[MediaPipe LLM Inference](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference)** | Runs Gemma packaged as a **`.task`** bundle (after conversion). |

**Vision vs text — important for Food AI:** MediaPipe’s LLM Inference API is documented mainly for **text-in → text-out** generation. **Food photos need vision** (image + text). For true on-device “photo → macros” you must either:

1. Use a **multimodal** on-device pipeline where Google (or another vendor) exposes **image+text** inference on your target OS/API level—verify current **Android / iOS** GenAI or ML APIs for **your** release year and devices; or  
2. Split the problem: a **tiny vision** step (classification/caption) plus **text Gemma** for reasoning and formatting macros; or  
3. Keep **vision on the server** (current `FOOD_AGENT_URL` design) and only move smaller pieces on-device later.

**Flutter:** there is no official “Gemma in Dart” package that replaces native runtimes. Typical approach is **native** MediaPipe (Kotlin/Swift) behind **platform channels** or a small **plugin**, same pattern as other heavy ML on Flutter.

**Practical constraints:** model download size, RAM (often **multi‑GB** peak for usable VLMs), battery/heat, and wide device variance—test on **mid‑range** phones, not only flagships.

Conversion from Hugging Face weights to a MediaPipe-compatible bundle is covered in Google’s **[conversion guide](https://ai.google.dev/gemma/docs/conversions/hf-to-mediapipe-task)** (workflow evolves; follow the linked docs for your model revision).

## HTTP API (agent contract)

**Endpoint:** `POST {FOOD_AGENT_URL}/analyze_food_url`  
**Headers:** `Content-Type: application/json`

**Request body**

| Field | Type | Description |
|-------|------|-------------|
| `s3_url` | string | Public `http(s)` URL of the meal image. Required for analysis. |
| `volume_cm3` | number | Assumed food volume in cubic centimeters (default in client if omitted: `250`). |
| `food_name` | string | User-entered meal label (may be empty). **Use as a strong hint** for prompting the VLM (e.g. disambiguate similar dishes). |

Example:

```json
{
  "s3_url": "https://example-bucket.s3.amazonaws.com/personId/food/photo.jpg",
  "volume_cm3": 250,
  "food_name": "grilled salmon bowl"
}
```

**Success:** HTTP `200` with a JSON body the client can parse in two ways:

1. **`output` as object** — Prefer `CaloriesProtocol`-compatible fields (calories, protein, carbs, fat), optionally with image URL overrides as implemented in `CaloriesProtocol.fromJson`.
2. **`intermediate_steps`** (LangChain-style agent) — List of steps; client extracts macros from `result` strings using regex (see `AIFoodCaloriesService` for `Protein:` / `Carbs:` / `Fat:` / `Total Calories:` and tool name `calculate_volume_calories`).

**Failure:** Non-200; client treats as `requestOk: false` and may set `needsAiRetry` on the meal row.

## Backend model guidance (Gemma family)

For **food images** (ingredients, cuisine, plate-level reasoning, portion hints), use a **small multimodal** stack:

1. **Primary recommendation — Gemma 4 (multimodal)**  
   Strong general and multimodal capabilities; suitable for **hosted** inference (not embedded in the APK). Size variants (e.g. E2B/E4B up to larger dense/MoE) trade latency/cost vs quality—pick based on your agent host.

2. **Alternatives** (from earlier evaluations; useful for cost/latency experiments)  
   - **PaliGemma 2** — Gemma-based, strong for detection-style prompts (“food / plate / bowl”) when fine-tuned or prompted carefully.  
   - **Moondream2/3, SmolVLM** — Very small VLMs when you need minimal footprint or experimentation.

Wire the chosen model **inside the food agent service**, not in the Flutter repo: keep API keys and model IDs on the server.

## Security notes

- Serve agent over **HTTPS** in production.  
- `s3_url` must be reachable by the agent (same considerations as any URL-fetching service).  
- Do not embed Vertex/Gemini API keys in the mobile client for this flow unless you accept key extraction risk; prefer the agent backend.
