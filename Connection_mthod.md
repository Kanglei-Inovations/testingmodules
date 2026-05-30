# Neural Link P2P - Connection Protocol

Establishing a decentralized peer-to-peer connection requires a "Neural Handshake" to synchronize WebRTC Session Description Protocols (SDPs). The platform now supports two distinct methods: **Auto Discovery (Zero-Touch)** and **Manual Entry (QR/Link)**.

---

### 🌐 METHOD 1: AUTO DISCOVERY (DHT/LAN) - Recommended
This method uses local network multicasting (mDNS/UDP) to autonomously discover peers and a dedicated TCP signaling server to exchange connection data automatically.

1. **Initiate Scan**: On the Home Page, tap **Create / Connect**, then select **DHT Auto Discovery** or **Nearby Discovery (LAN)** and tap **START DISCOVERY**.
2. **Radar Sweep**: A radar animation will begin, actively scanning the local network for other Neural Link nodes (`DiscoveryService` broadcasting).
3. **Peer Selection**: Discovered nodes will appear in the **AVAILABLE PEERS** list with real-time signal strength indicators.
4. **Auto-Handshake**: 
   - Tap **CONNECT** next to a peer.
   - The app will automatically generate an SDP offer and send it over the local network to the peer's TCP signaling port (`SignalingService`).
   - The remote peer will automatically receive it, generate an answer, and send it back.
5. **Link Established**: The WebRTC tunnel is established seamlessly without user intervention.

*Note: If the peer is already known (synced previously in the Isar database), the system will automatically trigger the handshake upon discovery, bypassing the selection list entirely.*

---

### 🔲 METHOD 2: MANUAL SIGNALING (QR/LINK)
Use this fallback method when devices are on different networks (requiring STUN/TURN routing) or auto-discovery fails.

**Phase A: Generate Offer (Device 1)**
1. On the Home Page, tap **Create / Connect** -> **Manual (QR / Link)** -> **START DISCOVERY**.
2. The system generates a compressed, Base64-encoded local node identity (SDP Offer).
3. Tap **GENERATE QR CODE** or **COPY SECURE LINK**.
4. Device 1 will wait in the background for the return signal.

**Phase B: Process & Reply (Device 2)**
1. On the Home Page, tap **Join with QR / Link**.
2. Choose **ACTIVATE NEURAL SCANNER** to scan Device 1's QR code, or **MANUAL DATA INJECTION** to paste the link.
3. Device 2 reads the offer, sets its remote description, and generates an answer.
4. The Cinematic Handshake UI (`NeuralHandshakeOverlay`) appears, showing the tunnel preparation.
5. Once ready, Device 2 generates its own QR/Link containing the Answer.

**Phase C: Finalize Link (Device 1)**
1. On Device 1 (which was waiting), tap **PROCESS REMOTE LINK** (or use **Join with QR / Link** from Home).
2. Scan or paste Device 2's Answer data.
3. The high-fidelity validation sequence runs, finalizing the WebRTC tunnel.

---

### 🟢 RESULT: CONNECTED NODE
- A glowing **CONNECTED NODE** card appears on your Home Page.
- View real-time metrics: **GPS Coordinates**, **Duration**, and **Signal Strength**.
- The `SyncEngine` will automatically run a background delta-sync of the database.
- Tap **OPEN NEURAL CHANNEL** to enter the P2P chat and share files.

---

### 📁 MEDIA TRANSMISSION PROTOCOL
The Neural Link supports high-fidelity transmission of images, videos, and PDF documents using a custom binary chunking protocol via the WebRTC DataChannel.

1.  **Chunking**: Files are split into **16KB binary packets** to bypass channel buffer limits.
2.  **Verification**: Every transmission is validated via **SHA256 hashing** upon arrival.
3.  **Media Handling**:
    - **Videos**: Received videos automatically generate a preview frame using `ThumbnailService`.
    - **PDFs**: The first page is rendered as a high-quality thumbnail.
4.  **Persistence**: Files are stored in the local node's secure storage, indexed via the **Isar Database** for offline access.
