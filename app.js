document.addEventListener('DOMContentLoaded', () => {
    // 1. Clock functionality
    const timeDisplay = document.getElementById('current-time');
    const dateDisplay = document.getElementById('current-date');

    function updateClock() {
        const now = new Date();
        timeDisplay.textContent = now.toLocaleTimeString('en-US', { hour12: false });
        dateDisplay.textContent = now.toISOString().split('T')[0];
    }

    setInterval(updateClock, 1000);
    updateClock();

    // 2. Alert System functionality
    const alertContainer = document.getElementById('alert-container');
    const emptyState = document.getElementById('empty-state');
    const alertCountDisplay = document.getElementById('alert-count');
    const simulateBtn = document.getElementById('test-alert-btn');

    let activeAlerts = [];
    let alertIdCounter = 0;

    const cameraNames = [
        "MAIN ENTRANCE", "PARKING LOT A", "SERVER ROOM",
        "LOBBY DESK", "WAREHOUSE BACK", "CAFETERIA"
    ];

    const eventTypes = [
        { type: "MOTION DETECTED", severity: "high", color: "text-red-500", bg: "bg-red-500/10", border: "border-red-500/30" },
        { type: "UNAUTHORIZED ACCESS", severity: "critical", color: "text-red-600", bg: "bg-red-600/10", border: "border-red-600/50" },
        { type: "SIGNAL LOSS", severity: "medium", color: "text-yellow-500", bg: "bg-yellow-500/10", border: "border-yellow-500/30" },
        { type: "DOOR FORCED", severity: "high", color: "text-orange-500", bg: "bg-orange-500/10", border: "border-orange-500/30" }
    ];

    function updateAlertCount() {
        const count = activeAlerts.length;
        alertCountDisplay.textContent = `${count} ACTIVE`;

        if (count > 0) {
            alertCountDisplay.classList.remove('bg-gray-800', 'text-gray-300');
            alertCountDisplay.classList.add('bg-red-500', 'text-white', 'animate-pulse');
            if (emptyState) emptyState.style.display = 'none';
        } else {
            alertCountDisplay.classList.add('bg-gray-800', 'text-gray-300');
            alertCountDisplay.classList.remove('bg-red-500', 'text-white', 'animate-pulse');
            if (emptyState) emptyState.style.display = 'block';
        }
    }

    function createAlert(camId, eventDetails) {
        const id = ++alertIdCounter;
        const now = new Date();
        const timeString = now.toLocaleTimeString('en-US', { hour12: false });

        activeAlerts.push({ id, camId });

        // Highlight Camera Element
        const camElement = document.getElementById(`cam-${camId}`);
        if (camElement) {
            camElement.classList.add('border-red-500', 'shadow-[0_0_15px_rgba(239,68,68,0.2)]');
            camElement.classList.remove('border-gray-800');

            const indicator = camElement.querySelector('.status-indicator');
            if (indicator) {
                indicator.classList.remove('bg-green-500');
                indicator.classList.add('bg-red-500', 'animate-pulse');
            }
        }

        // Create Alert UI Item
        const alertEl = document.createElement('div');
        alertEl.id = `alert-item-${id}`;
        alertEl.className = `p-3 rounded border ${eventDetails.bg} ${eventDetails.border} transition-all duration-300 animate-[fadeIn_0.3s_ease-out]`;

        alertEl.innerHTML = `
            <div class="flex justify-between items-start mb-1">
                <span class="text-xs font-bold ${eventDetails.color} tracking-wider">${eventDetails.type}</span>
                <span class="text-[10px] text-gray-500 font-mono">${timeString}</span>
            </div>
            <div class="text-sm text-gray-300 mb-2">
                Camera ${camId}: ${cameraNames[camId - 1]}
            </div>
            <button class="text-xs text-gray-400 hover:text-white border border-gray-600 hover:border-gray-400 px-2 py-1 rounded transition-colors" onclick="resolveAlert(${id}, ${camId})">
                ACKNOWLEDGE
            </button>
        `;

        // Prepend to container
        alertContainer.insertBefore(alertEl, alertContainer.firstChild);
        updateAlertCount();
    }

    // Expose resolve logic globally so onclick works
    window.resolveAlert = function(alertId, camId) {
        // Remove from UI
        const alertEl = document.getElementById(`alert-item-${alertId}`);
        if (alertEl) {
            alertEl.style.opacity = '0';
            alertEl.style.transform = 'translateX(20px)';
            setTimeout(() => {
                alertEl.remove();
            }, 300);
        }

        // Remove from state
        activeAlerts = activeAlerts.filter(a => a.id !== alertId);
        updateAlertCount();

        // Check if camera has other active alerts before resetting its style
        const camHasOtherAlerts = activeAlerts.some(a => a.camId === camId);
        if (!camHasOtherAlerts) {
            const camElement = document.getElementById(`cam-${camId}`);
            if (camElement) {
                camElement.classList.remove('border-red-500', 'shadow-[0_0_15px_rgba(239,68,68,0.2)]');
                camElement.classList.add('border-gray-800');

                const indicator = camElement.querySelector('.status-indicator');
                if (indicator) {
                    indicator.classList.remove('bg-red-500', 'animate-pulse');
                    indicator.classList.add('bg-green-500');
                }
            }
        }
    };

    // Simulation trigger
    simulateBtn.addEventListener('click', () => {
        const randomCam = Math.floor(Math.random() * 6) + 1; // 1 to 6
        const randomEvent = eventTypes[Math.floor(Math.random() * eventTypes.length)];
        createAlert(randomCam, randomEvent);
    });

    // Add custom animation for alert entry
    const style = document.createElement('style');
    style.innerHTML = `
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }
    `;
    document.head.appendChild(style);

    console.log("CCTV Monitoring System Ready");
});