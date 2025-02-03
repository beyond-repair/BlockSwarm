```javascript
import { ethers } from "ethers";

export async function readNFC() {
    if (!("NDEFReader" in window)) {
        throw new Error("WebNFC not supported");
    }

    const reader = new NDEFReader();
    await reader.scan();

    return new Promise((resolve, reject) => {
        reader.onreading = (event) => {
            const decoder = new TextDecoder();
            const data = decoder.decode(event.message.records[0].data);
            const signature = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(data));
            resolve({ data, signature });
        };

        reader.onerror = (error) => {
            reject(error);
        };
    });
}
```