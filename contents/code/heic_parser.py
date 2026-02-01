#!/usr/bin/env python3
"""
HEIC Dynamic Desktop Parser
Extracts timing metadata and images from Apple's Dynamic Desktop HEIC files
"""

import sys
import json
import os
import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Tuple


def check_dependencies() -> Tuple[bool, str]:
    """Check if required tools are available"""
    try:
        subprocess.run(['exiftool', '-ver'], capture_output=True, check=True)
        exiftool_available = True
    except (subprocess.CalledProcessError, FileNotFoundError):
        exiftool_available = False

    try:
        subprocess.run(['magick', '-version'], capture_output=True, check=True)
        imagemagick_available = True
    except (subprocess.CalledProcessError, FileNotFoundError):
        imagemagick_available = False

    if not exiftool_available and not imagemagick_available:
        return False, "Neither exiftool nor ImageMagick found. Please install one of them."

    return True, "exiftool" if exiftool_available else "imagemagick"


def extract_metadata_exiftool(heic_path: str) -> Optional[Dict]:
    """Extract metadata using exiftool"""
    try:
        result = subprocess.run(
            ['exiftool', '-j', '-G', heic_path],
            capture_output=True,
            text=True,
            check=True
        )
        metadata = json.loads(result.stdout)
        return metadata[0] if metadata else None
    except Exception as e:
        print(f"Error extracting metadata: {e}", file=sys.stderr)
        return None


def parse_apple_metadata(metadata: Dict) -> List[Dict[str, float]]:
    """Parse Apple's solar position metadata from HEIC"""
    # Apple stores timing as solar azimuth (si) and altitude (ap) values
    # We'll convert these to approximate times of day

    solar_data = []

    # Look for common metadata fields
    for key in metadata.keys():
        if 'solar' in key.lower() or 'appearance' in key.lower():
            print(f"Found metadata: {key} = {metadata[key]}", file=sys.stderr)

    # If we can't find solar data, create a default 24-hour schedule
    # based on number of images in the HEIC
    return solar_data


def get_image_count(heic_path: str) -> int:
    """Get the number of images in HEIC file"""
    try:
        # Try to identify number of images using ImageMagick
        result = subprocess.run(
            ['magick', 'identify', heic_path],
            capture_output=True,
            text=True
        )
        lines = result.stdout.strip().split('\n')
        return len(lines)
    except:
        # Default assumption for macOS dynamic desktops
        return 16


def create_time_schedule(image_count: int) -> List[str]:
    """Create evenly distributed time schedule based on image count"""
    if image_count <= 0:
        return ["00:00"]

    minutes_per_image = (24 * 60) // image_count
    schedule = []

    for i in range(image_count):
        total_minutes = i * minutes_per_image
        hours = total_minutes // 60
        minutes = total_minutes % 60
        schedule.append(f"{hours:02d}:{minutes:02d}")

    return schedule


def extract_images(heic_path: str, output_dir: str, tool: str = "imagemagick") -> List[str]:
    """Extract individual images from HEIC file"""
    heic_path_obj = Path(heic_path)
    output_path_obj = Path(output_dir)
    output_path_obj.mkdir(parents=True, exist_ok=True)

    base_name = heic_path_obj.stem
    extracted_files = []

    try:
        if tool == "imagemagick":
            # ImageMagick extracts all frames automatically
            output_pattern = output_path_obj / f"{base_name}_%02d.png"
            subprocess.run(
                ['magick', 'convert', heic_path, str(output_pattern)],
                check=True,
                capture_output=True
            )

            # Find all extracted files
            for i in range(100):  # Arbitrary max
                potential_file = output_path_obj / f"{base_name}_{i:02d}.png"
                if potential_file.exists():
                    extracted_files.append(str(potential_file))
                else:
                    break
        else:
            # For exiftool, we'd need different approach
            print("Image extraction with exiftool not implemented", file=sys.stderr)
            return []

        return extracted_files

    except subprocess.CalledProcessError as e:
        print(f"Error extracting images: {e}", file=sys.stderr)
        return []


def heic_to_schedule(heic_path: str, output_dir: Optional[str] = None) -> Dict:
    """
    Convert HEIC Dynamic Desktop to schedule JSON format

    Returns:
        {
            "schedule": [{"time": "00:00", "image": "/path/to/image.png"}, ...],
            "extracted_dir": "/path/to/extracted/images",
            "image_count": 16
        }
    """
    if not os.path.exists(heic_path):
        return {"error": f"File not found: {heic_path}"}

    # Check dependencies
    available, tool = check_dependencies()
    if not available:
        return {"error": tool}

    # Set output directory
    if output_dir is None:
        heic_dir = Path(heic_path).parent
        output_dir = heic_dir / f".{Path(heic_path).stem}_extracted"

    output_dir = str(output_dir)

    # Extract metadata
    if tool == "exiftool":
        metadata = extract_metadata_exiftool(heic_path)
        if metadata:
            print(f"Metadata keys: {list(metadata.keys())}", file=sys.stderr)

    # Extract images
    extracted_images = extract_images(heic_path, output_dir, tool)

    if not extracted_images:
        return {"error": "Failed to extract images from HEIC file"}

    # Create time schedule
    image_count = len(extracted_images)
    time_schedule = create_time_schedule(image_count)

    # Build schedule
    schedule = []
    for i, (time, image_path) in enumerate(zip(time_schedule, extracted_images)):
        schedule.append({
            "time": time,
            "image": image_path
        })

    return {
        "schedule": schedule,
        "extracted_dir": output_dir,
        "image_count": image_count,
        "source_heic": heic_path
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: heic_parser.py <path-to-heic-file> [output-directory]")
        print("\nConverts Apple Dynamic Desktop HEIC files to Kuallpapers schedule format")
        sys.exit(1)

    heic_path = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else None

    result = heic_to_schedule(heic_path, output_dir)

    if "error" in result:
        print(f"Error: {result['error']}", file=sys.stderr)
        sys.exit(1)

    # Output JSON schedule in Kuallpapers format
    schedule_json = []
    for entry in result["schedule"]:
        schedule_json.append({
            "time": entry["time"],
            "image": entry["image"]
        })

    print(json.dumps(schedule_json, indent=2))

    # Print info to stderr
    print(f"\nExtracted {result['image_count']} images to: {result['extracted_dir']}", file=sys.stderr)
    print(f"Source HEIC: {result['source_heic']}", file=sys.stderr)


if __name__ == "__main__":
    main()
