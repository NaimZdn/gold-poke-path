// =====================================================
// PokePath TD Gold Tracker - Browser Script
// =====================================================
// Instructions:
// 1. Ouvrir PokePath TD dans le navigateur
// 2. Ouvrir les DevTools (F12 ou Cmd+Option+I)
// 3. Aller dans l'onglet Console
// 4. Copier-coller ce script et appuyer sur Entrée
// =====================================================

(function() {
  // Configuration - Modifier l'adresse selon votre setup
  // Local: ws://localhost:3001
  // Tailscale: ws://100.74.234.38:3001
  const WS_URL = 'ws://localhost:3001';

  let ws = null;
  let reconnectAttempts = 0;
  const MAX_RECONNECT_ATTEMPTS = 10;
  const RECONNECT_DELAY = 3000;
  const UPDATE_INTERVAL = 1000; // 1 seconde

  function getGold() {
    try {
      const data = localStorage.getItem('data');
      if (!data) return null;

      const parsed = JSON.parse(data);
      return parsed?.save?.player?.gold ?? null;
    } catch (err) {
      console.error('[GoldTracker] Erreur lecture localStorage:', err);
      return null;
    }
  }

  function connect() {
    if (ws && ws.readyState === WebSocket.OPEN) return;

    console.log(`[GoldTracker] Connexion à ${WS_URL}...`);

    try {
      ws = new WebSocket(WS_URL);

      ws.onopen = () => {
        console.log('[GoldTracker] ✅ Connecté au serveur');
        reconnectAttempts = 0;
        startTracking();
      };

      ws.onclose = () => {
        console.log('[GoldTracker] ❌ Déconnecté');
        scheduleReconnect();
      };

      ws.onerror = (err) => {
        console.error('[GoldTracker] Erreur WebSocket:', err);
      };

    } catch (err) {
      console.error('[GoldTracker] Erreur de connexion:', err);
      scheduleReconnect();
    }
  }

  function scheduleReconnect() {
    if (reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
      reconnectAttempts++;
      console.log(`[GoldTracker] Reconnexion dans ${RECONNECT_DELAY/1000}s (tentative ${reconnectAttempts}/${MAX_RECONNECT_ATTEMPTS})`);
      setTimeout(connect, RECONNECT_DELAY);
    } else {
      console.error('[GoldTracker] ❌ Nombre max de tentatives atteint. Rechargez la page pour réessayer.');
    }
  }

  let trackingInterval = null;
  let lastGold = null;

  function startTracking() {
    if (trackingInterval) clearInterval(trackingInterval);

    trackingInterval = setInterval(() => {
      if (ws?.readyState !== WebSocket.OPEN) return;

      const gold = getGold();
      if (gold === null) return;

      // Envoyer seulement si la valeur a changé
      if (gold !== lastGold) {
        lastGold = gold;
        ws.send(JSON.stringify({
          type: 'gold_update',
          gold: gold,
          ts: Date.now()
        }));
        console.log(`[GoldTracker] 💰 Gold: ${gold.toLocaleString()}`);
      }
    }, UPDATE_INTERVAL);

    console.log('[GoldTracker] 🎮 Tracking démarré');
  }

  function stop() {
    if (trackingInterval) {
      clearInterval(trackingInterval);
      trackingInterval = null;
    }
    if (ws) {
      ws.close();
      ws = null;
    }
    console.log('[GoldTracker] 🛑 Tracking arrêté');
  }

  // Exposer les fonctions pour contrôle manuel
  window.GoldTracker = {
    start: connect,
    stop: stop,
    getGold: getGold,
    setUrl: (url) => {
      stop();
      WS_URL = url;
      connect();
    }
  };

  // Démarrer automatiquement
  connect();

  console.log('[GoldTracker] 🎮 Script chargé!');
  console.log('[GoldTracker] Commandes: GoldTracker.start(), GoldTracker.stop(), GoldTracker.getGold()');
})();
