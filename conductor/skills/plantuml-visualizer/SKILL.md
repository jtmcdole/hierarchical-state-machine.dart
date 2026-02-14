---
name: plantuml-visualizer
description: Encodes PlantUML text into a URL-safe parameter and downloads the resulting PNG. Use when you need to visualize a state machine blueprint or verify the correctness of generated PlantUML code.
---

# PlantUML Visualizer

This skill provides a mechanism to encode PlantUML text and download the resulting PNG diagram.

## Workflow

1.  **Identify PlantUML Text**: Obtain the PlantUML string you wish to visualize.
2.  **Visualize and Download**: Run the provided Node.js script to generate the URL and download the image.
    ```bash
    node scripts/visualize.cjs "<plantuml-text>" [output-path.png]
    ```
3.  **Verify**: 
    -   If an `output-path.png` was provided, use `read_file` on the PNG to "see" the result.
    -   Otherwise, use the provided URL to view the diagram in a browser.

## Implementation Details

- **Encoding**: Uses UTF-8 -> Deflate (Raw) -> Custom PlantUML Base64 mapping.
- **Server**: Default server is `https://plantuml.mcdole.org`.
