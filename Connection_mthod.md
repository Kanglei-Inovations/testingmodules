# Neural Link P2P - Connection Protocol

Establishing a decentralized peer-to-peer connection requires a specific "Neural Handshake" process. The platform features a guided, bidirectional flow to ensure both nodes synchronize correctly through a cinematic signaling sequence.

---

### 🛰️ PHASE 1: INITIAL SIGNAL (Device A)
1.  **Initialize**: On the Home Page, tap **⚡ INITIALIZE OFFER**.
2.  **Sequence**: A holographic overlay will appear, calibrating your local node:
    - `🌐 INITIALIZING LOCAL NODE...`
    - `🛰️ DISCOVERING NETWORK ROUTE...`
    - `🔍 ANALYZING NETWORK PATHS...`
    - `🧠 GENERATING NODE IDENTITY...`
3.  **Transmit**: Once `🟢 NODE IDENTITY ACTIVE` appears, select **GENERATE QR** or **SHARE LINK**.
4.  **Radar Sweep**: After sharing, Device A enters a **WAITING FOR RESPONSE STREAM** state. You will see a radar sweep animation and pulse rings. **Do not close this overlay.**

---

### 📥 PHASE 2: SIGNAL RECEPTION (Device B)
1.  **Process**: On Device B, tap **🧠 PROCESS ANSWER**.
2.  **Inject**: Use the Neural Scanner to scan the QR or paste the link from Device A.
3.  **Automated Response**: Device B will run its own synchronization sequence:
    - `📥 RECEIVING REMOTE NODE STREAM...`
    - `🔎 VALIDATING REMOTE NODE...`
    - `🛰️ GENERATING RESPONSE STREAM...`
    - `🔄 PREPARING SYNC TUNNEL...`
4.  **Response Generated**: Once `🟢 RESPONSE STREAM READY` appears, Device B must transmit the return signal back to Device A to finalize the link.
5.  **Share**: Tap **SHOW RESPONSE QR** or **SHARE RESPONSE LINK** on Device B.

---

### 🔄 PHASE 3: NEURAL LINK FINALIZATION (Device A)
1.  **Receive**: On **Device A** (still in the waiting overlay), locate the **📥 RECEIVE RESPONSE STREAM** section.
2.  **Inject**: Scan Device B's response QR or paste their response link.
3.  **Cinematic Sequence**: The app will execute a high-fidelity validation sequence:
    - `🛰️ VALIDATING RESPONSE...`
    - `🔄 SYNCHRONIZING NETWORK PATHS...`
    - `🔗 ESTABLISHING P2P TUNNEL...`
    - `⚡ OPENING DATA CHANNEL...`
4.  **Success**: Once `🟢 NEURAL LINK ESTABLISHED` appears, the overlay will automatically close, returning you to the Home Page.

---

### 🟢 RESULT: CONNECTED NODE
- A glowing **CONNECTED NODE** card will appear on your Home Page.
- View real-time metrics: **Connection Duration**, **Protocol Version**, and **Sync Status**.
- Tap **OPEN NEURAL CHANNEL** to enter the P2P chat.

---

### 🦾 OPERATIONAL RULES
- **Handshake Loop**: Device A sends an offer -> Device B generates an answer -> Device A must receive that answer.
- **State Persistence**: Device A must stay in the "Waiting" state to finalize. If the overlay is closed prematurely, you may need to restart the handshake.
- **Visual Cues**: Shimmering borders and pulsing nodes indicate an active, healthy neural link.
- **Emergency Reset**: If a handshake fails, use the **Refresh** icon to reset your node identity.

---

### 📁 MEDIA TRANSMISSION PROTOCOL
The Neural Link supports high-fidelity transmission of images, videos, and PDF documents using a custom binary chunking protocol.

1.  **Chunking**: Files are split into **16KB binary packets** to ensure stability over the WebRTC DataChannel.
2.  **Verification**: Every transmission is validated via **SHA256 hashing** upon arrival.
3.  **Media Handling**:
    - **Videos**: Received videos automatically generate a preview frame. Tap the **Play** icon to launch the system player.
    - **PDFs**: The first page is rendered as a thumbnail. Tap to open in the default PDF viewer.
    - **Images**: Automatically compressed and displayed with high-speed rendering.
4.  **Persistence**: Files are stored in the local node's secure storage, indexed via the **Isar Database** for offline access.
