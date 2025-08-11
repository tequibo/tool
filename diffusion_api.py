from fastapi import FastAPI, UploadFile, File, Form
from diffusers import StableDiffusionPipeline, ControlNetModel
import torch
from PIL import Image
import io
import base64
from typing import List
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import os
import datetime

app = FastAPI()

from diffusers.utils import load_image
from diffusers import (
    ControlNetModel,
    StableDiffusionControlNetPipeline,
    DPMSolverMultistepScheduler,
)

# Define model and checkpoint
checkpoint = "lllyasviel/control_v11f1p_sd15_depth"
prompt = "black background, fire, smoke, depth of field"
model = "runwayml/stable-diffusion-v1-5"

# Ensure the output folder exists

controlnet = ControlNetModel.from_pretrained(checkpoint)
pipe = StableDiffusionControlNetPipeline.from_pretrained(
    model, controlnet=controlnet, safety_checker=None
)

pipe.enable_attention_slicing()
pipe.to("mps")
pipe.scheduler = DPMSolverMultistepScheduler.from_config(pipe.scheduler.config, use_karras_sigmas=True)
pipe.enable_attention_slicing()
generator = torch.manual_seed(0)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Update this to restrict to specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/generate")
async def generate_images(
    files: List[UploadFile] = File(...),
    prompt: str = Form("solid black background, silver statue, light"),  # Add prompt parameter
    steps: int = Form(15),  # Add num_inference_steps parameter with a default value
):
    output_folder = f"/Users/sasha/loops/controlnet_output/{prompt.replace(' ', '_')[:10]}_{datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}"  # Define the output folder to save images
    if len(files) > 2:
        os.makedirs(output_folder, exist_ok=True)
    
    print(f"Received prompt: {prompt}")
    print(f"Received steps: {steps}")
    print(f"Number of files: {len(files)}")
    output_folder = f"/Users/sasha/loops/controlnet_output/{prompt.replace(' ', '_')[:10]}_{datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}"  # Define the output folder to save images
    if len(files)>2:
        os.makedirs(output_folder, exist_ok=True)
    print("prompt: "+prompt+" steps:  "+str(steps)+" frames:  "+str(len(files))) 
    frames = []
    try:
        for idx, file in enumerate(files):
            image_data = await file.read()
            input_image = Image.open(io.BytesIO(image_data)).convert("RGB")
            control_net_input = load_image(input_image)
            generator = torch.Generator(device="mps").manual_seed(10107)
            output_image = pipe(prompt, num_inference_steps=steps, guidance_scale=8, controlnet_conditioning_scale=1.0, guess_mode=False, negative_prompt="", generator=generator, image=control_net_input).images[0]
            buffered = io.BytesIO()
            output_image.save(buffered, format="JPEG")
            frames.append(base64.b64encode(buffered.getvalue()).decode('utf-8'))

            # Save the generated image //todo fix frame1
            # image_name = f"{file.filename}"
            image_name = f"{idx+1:03d}.jpeg" 
            image_path = os.path.join(output_folder, image_name)
            if len(files)>2:
                output_image.save(image_path)

        return {"frames": frames}
    except Exception as e:
        print(f"Error during image generation: {e}")
        return JSONResponse(content={"error": str(e)}, status_code=500)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
