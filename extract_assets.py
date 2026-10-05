import os
from pypdf import PdfReader
from PIL import Image
import io

pdf1_path = r"C:\Users\HP\.gemini\antigravity\brain\e4f79e4d-2ff3-45b7-a805-f375a2b15f2f\.user_uploaded\media_1790489024940.pdf"
pdf2_path = r"C:\Users\HP\.gemini\antigravity\brain\e4f79e4d-2ff3-45b7-a805-f375a2b15f2f\.user_uploaded\media_1790489029827.pdf"

out_dir = r"C:\Users\HP\.gemini\antigravity\scratch\KitchenChaos\assets"
os.makedirs(out_dir, exist_ok=True)

def extract_from_pdf(pdf_path, prefix):
    reader = PdfReader(pdf_path)
    print(f"Reading {pdf_path}: {len(reader.pages)} pages")
    count = 0
    for page_idx, page in enumerate(reader.pages):
        for img_idx, img in enumerate(page.images):
            ext = img.name.split('.')[-1]
            out_name = f"{prefix}_p{page_idx+1}_{img_idx+1}_{img.name}"
            out_path = os.path.join(out_dir, out_name)
            with open(out_path, "wb") as f:
                f.write(img.data)
            print(f"Saved: {out_name} ({len(img.data)} bytes)")
            count += 1
    return count

print("Extracting PDF 1...")
c1 = extract_from_pdf(pdf1_path, "pdf1")
print("Extracting PDF 2...")
c2 = extract_from_pdf(pdf2_path, "pdf2")
print(f"Extracted total {c1 + c2} images.")
