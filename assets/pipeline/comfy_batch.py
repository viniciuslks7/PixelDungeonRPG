import os
import json
import urllib.request
import urllib.parse
from urllib.error import URLError, HTTPError
from PIL import Image

COMFY_URL = "http://127.0.0.1:8188"
WORKFLOW_PATH = "workflow_api.json"
OUTPUT_DIR = "../enemies"

PROMPTS = {
    "spr_enemy_slime_idle": "Create a pixel art sprite for a green slime enemy in a dark fantasy roguelike. 32x32 canvas, transparent background, one character only, centered composition, top-down dungeon crawler perspective. Rounded gelatinous body, low silhouette, bright green main body with darker inner core, subtle gooey highlights, irregular base, simple hostile creature design, readable at very small size, cute-dangerous balance, clean retro pixel art.",
    "spr_enemy_skeleton_idle": "Create a pixel art sprite for a skeleton enemy in a dark fantasy roguelike. 32x32 canvas, transparent background, one character only, centered composition, top-down dungeon crawler perspective with slight frontal readability. Thin humanoid bone structure, skull clearly readable, yellowed bones, scraps of rusty armor, dark gaps between ribs and limbs, small rusted weapon or shield fragment allowed, menacing but simple, readable silhouette, classic dungeon enemy look.",
    "spr_enemy_bat_idle": "Create a pixel art sprite for a bat enemy in a dark fantasy roguelike. 32x32 canvas, transparent background, one character only, centered composition, top-down dungeon crawler perspective. Small body, wide wings forming a strong X or diamond silhouette, dark purple and cold gray palette, tiny aggressive face, fast and fragile feel, strong contrast, readable at very small size, retro dungeon monster sprite."
}

def queue_prompt(prompt_workflow):
    p = {"prompt": prompt_workflow}
    data = json.dumps(p).encode('utf-8')
    req = urllib.request.Request(f"{COMFY_URL}/prompt", data=data)
    try:
        response = urllib.request.urlopen(req)
        return json.loads(response.read())
    except HTTPError as e:
        return {"error": str(e), "content": e.read().decode('utf-8')}
    except URLError as e:
        return {"error": str(e)}

def run_comfy_generation():
    print("--- Inciando Geração em Lote no ComfyUI ---")
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    with open(WORKFLOW_PATH, 'r') as f:
        template_str = f.read()

    report = {"successful": [], "failed": []}
    seed = 1000

    for name, text in PROMPTS.items():
        print(f"Gerando: {name} (Seed: {seed})")
        workflow_str = template_str.replace("{prompt_placeholder}", text)
        workflow_str = workflow_str.replace("{seed_placeholder}", str(seed))
        workflow_str = workflow_str.replace("{output_prefix}", name)
        workflow_str = workflow_str.replace("{negative_placeholder}", "side view, isometric, noisy")
        
        workflow = json.loads(workflow_str)
        
        # O model no CheckpointLoader vai bater num modelo placeholder if empty. 
        # Sabemos que pode falhar se v1-5-pruned-emaonly.safetensors faltar.
        
        result = queue_prompt(workflow)
        
        if "error" in result:
            print(f"ERRO API para {name}: {result['error']}")
            report["failed"].append({
                "name": name, 
                "seed": seed, 
                "error": result.get("content", result['error'])
            })
        else:
            print(f"Sucesso na fila (Prompt ID: {result.get('prompt_id')})")
            report["successful"].append({
                "name": name,
                "seed": seed,
                "prompt_id": result.get('prompt_id')
            })
        seed += 1
        
    return report

def generate_master_spritesheet():
    print("\n--- Gerando Spritesheets Mestre (Archer, Mage, Warrior) ---")
    base_dir = "../characters/pixellab"
    players_dir = "../characters/players"
    os.makedirs(players_dir, exist_ok=True)
    
    classes = ["archer", "mage", "warrior_humano"]
    stats = {}
    
    for cls in classes:
        cls_dir = os.path.join(base_dir, cls, "animations")
        if not os.path.exists(cls_dir):
            print(f"Aviso: Diretório de animações não encontrado para {cls} ({cls_dir})")
            continue
            
        anim_folders = os.listdir(cls_dir)
        frames_list = []
        
        # Simplificado: Pegar a animação (ex: animating-c39c88d4) direction east
        for anim in anim_folders:
            anim_path = os.path.join(cls_dir, anim, "east")
            if os.path.exists(anim_path):
                frames = [f for f in os.listdir(anim_path) if f.endswith('.png')]
                frames.sort()
                for f in frames:
                    frames_list.append(os.path.join(anim_path, f))
        
        if not frames_list:
            print(f"Sem frames exportáveis para {cls}.")
            continue
            
        # Pega a primeira imagem para dimensão
        first_img = Image.open(frames_list[0])
        w, h = first_img.size
        
        # Grid horizontal para sheet
        sheet_w = w * len(frames_list)
        sheet_h = h
        
        sheet = Image.new("RGBA", (sheet_w, sheet_h), (0,0,0,0))
        for i, path in enumerate(frames_list):
            img = Image.open(path)
            sheet.paste(img, (i*w, 0))
            
        output_file = os.path.join(players_dir, f"spr_{cls}_sheet.png")
        sheet.save(output_file)
        stats[cls] = {"frames": len(frames_list), "size": f"{w}x{h}", "output": output_file}
        print(f"Spritesheet salva: {output_file} ({len(frames_list)} frames horizontais)")
        
    return stats

def main():
    report_data = {
        "comfy_batch": run_comfy_generation(),
        "spritesheets": generate_master_spritesheet()
    }
    
    report_path = "pipeline_report.json"
    with open(report_path, "w") as f:
        json.dump(report_data, f, indent=4)
        
    print(f"\nPipeline Finalizada. Relatório gerado em {report_path}")

if __name__ == "__main__":
    main()
