// Camera helper functions for Flutter web
// Enhanced torch/flashlight support for mobile devices
// Load jsQR library dynamically
(function() {
  // Check if jsQR is already loaded
  if (typeof jsQR !== 'undefined') {
    console.log('jsQR already available');
    return;
  }
  
  const script = document.createElement('script');
  script.src = 'https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.js';
  script.onload = function() {
    console.log('jsQR library loaded successfully');
    // Test the library
    if (typeof jsQR !== 'undefined') {
      console.log('jsQR is ready for use');
    }
  };
  script.onerror = function() {
    console.error('Failed to load jsQR library');
  };
  document.head.appendChild(script);
})();

// Test torch support on page load
window.addEventListener('load', function() {
  console.log('Testing torch support...');
  
  if (navigator.mediaDevices && navigator.mediaDevices.getSupportedConstraints) {
    const supportedConstraints = navigator.mediaDevices.getSupportedConstraints();
    console.log('Supported constraints:', supportedConstraints);
    
    if (supportedConstraints.torch) {
      console.log('Torch constraint is supported by this browser');
    } else {
      console.warn('Torch constraint is not supported by this browser');
    }
  }
});
// Global state for torch management
let torchMaintenanceInterval = null;
let currentTorchState = false;
let currentTrack = null;
let isInAppWebView = false;

// Detect InAppWebView environment
(function detectInAppWebView() {
  // Check for InAppWebView user agent or specific properties
  const userAgent = navigator.userAgent.toLowerCase();
  const hasInAppWebViewMarkers = userAgent.includes('flutter') || 
                                 userAgent.includes('inappwebview') ||
                                 window.flutter_inappwebview !== undefined ||
                                 window.webkit !== undefined;
  
  isInAppWebView = hasInAppWebViewMarkers;
  console.log('InAppWebView detected:', isInAppWebView);
  
  if (isInAppWebView) {
    console.log('Using InAppWebView-optimized torch handling');
  }
})();

// Comprehensive flash/torch control with persistence
window.toggleFlashlight = async function(track, enable) {
  try {
    console.log('Attempting to toggle flashlight:', enable, 'Track:', track);
    
    if (!track) {
      console.error('No track provided to toggleFlashlight');
      return false;
    }
    
    // Store track reference for maintenance
    currentTrack = track;
    
    // Stop any existing torch maintenance
    if (torchMaintenanceInterval) {
      clearInterval(torchMaintenanceInterval);
      torchMaintenanceInterval = null;
    }
    
    // If disabling, try multiple formats for maximum compatibility
    if (!enable) {
      const disableConstraints = [
        { advanced: [{ torch: false }] },
        { torch: false },
        { video: { torch: false } },
        { video: { advanced: [{ torch: false }] } }
      ];
      
      for (const constraint of disableConstraints) {
        try {
          await track.applyConstraints(constraint);
          currentTorchState = false;
          console.log('Torch disabled successfully with constraint:', constraint);
          return true;
        } catch (e) {
          console.log('Failed to disable torch with constraint:', constraint, e);
        }
      }
      
      // If all disable attempts failed, still return true to avoid confusion
      currentTorchState = false;
      return true;
    }
    
    // For enabling torch, try multiple constraint formats in order of reliability
    const constraintFormats = [
      { advanced: [{ torch: true }] },
      { torch: true },
      { video: { advanced: [{ torch: true }] } },
      { video: { torch: true } }
    ];
    
    let success = false;
    let lastError = null;
    
    for (const constraints of constraintFormats) {
      try {
        console.log('Trying constraint format:', constraints);
        await track.applyConstraints(constraints);
        
        // Wait a moment and verify
        await new Promise(resolve => setTimeout(resolve, 300));
        
        // Check multiple verification methods
        let verified = false;
        
        // Method 1: Check settings
        try {
          const settings = track.getSettings();
          console.log('Track settings after constraint:', settings);
          if (settings && settings.torch === true) {
            console.log('Torch verified via settings');
            verified = true;
          }
        } catch (e) {
          console.log('Settings check failed:', e);
        }
        
        // Method 2: Check capabilities
        if (!verified) {
          try {
            const capabilities = track.getCapabilities();
            if (capabilities && capabilities.torch === true) {
              console.log('Torch capability confirmed, assuming constraint worked');
              verified = true;
            }
          } catch (e) {
            console.log('Capabilities check failed:', e);
          }
        }
        
        // Method 3: Assume success if constraint didn't throw an error
        if (!verified) {
          console.log('No verification available, but constraint applied without error - assuming success');
          verified = true;
        }
        
        if (verified) {
          console.log('Torch enabled successfully with format:', constraints);
          success = true;
          break;
        }
      } catch (e) {
        console.log('Constraint format failed:', constraints, e.message);
        lastError = e;
      }
    }
    
    if (success) {
      currentTorchState = true;
      
      // Set up torch maintenance to keep it continuously lit
      console.log('Setting up torch maintenance');
      
      // Clear any existing maintenance first
      if (torchMaintenanceInterval) {
        clearInterval(torchMaintenanceInterval);
      }
      
      torchMaintenanceInterval = setInterval(async () => {
        try {
          if (currentTrack && currentTorchState) {
            // Simple maintenance - just reapply the basic constraint
            await currentTrack.applyConstraints({ advanced: [{ torch: true }] });
            console.log('Torch maintenance applied');
          }
        } catch (e) {
          // Ignore maintenance failures to avoid disrupting the main functionality
          console.log('Torch maintenance failed (normal on some devices):', e.message);
        }
      }, 500); // Less frequent maintenance to avoid conflicts
      
      return true;
    }
    
    console.warn('All torch enable methods failed. Last error:', lastError);
    return false;
  } catch (e) {
    console.error('Flash toggle error:', e);
    return false;
  }
};

// Stop torch maintenance
window.stopTorchMaintenance = function() {
  if (torchMaintenanceInterval) {
    clearInterval(torchMaintenanceInterval);
    torchMaintenanceInterval = null;
    currentTorchState = false;
    currentTrack = null;
    console.log('Torch maintenance stopped');
  }
};

window.getTrackCapabilities = function(track) {
  try {
    if (track && typeof track.getCapabilities === 'function') {
      return track.getCapabilities();
    }
    return null;
  } catch (e) {
    console.error('Error getting track capabilities:', e);
    return null;
  }
};

window.hasTorch = function(capabilities) {
  try {
    return capabilities && capabilities.torch === true;
  } catch (e) {
    console.error('Error checking torch capability:', e);
    return false;
  }
};

window.applyConstraints = async function(track, constraints) {
  try {
    if (track && typeof track.applyConstraints === 'function') {
      await track.applyConstraints(constraints);
      return true;
    }
    return false;
  } catch (e) {
    console.error('Error applying constraints:', e);
    throw e;
  }
};

// QR code detection using jsQR library
window.detectQRCode = function(imageData, width, height) {
  try {
    // Check if jsQR is available
    if (typeof jsQR !== 'undefined') {
      const code = jsQR(imageData, width, height, {
        inversionAttempts: "attemptBoth",
      });
      if (code && code.data && code.data.trim().length > 0) {
        console.log('QR Code detected:', code.data);
        return code.data;
      }
    } else {
      console.warn('jsQR library not loaded');
    }
    return null;
  } catch (e) {
    console.error('Error detecting QR code:', e);
    return null;
  }
};

// Enhanced QR code processing function (fallback)
window.processImageForQR = function(canvas) {
  try {
    if (!canvas) return null;
    
    const context = canvas.getContext('2d');
    const imageData = context.getImageData(0, 0, canvas.width, canvas.height);
    
    const result = window.detectQRCode(imageData.data, canvas.width, canvas.height);
    return result;
  } catch (e) {
    console.error('Error processing image for QR:', e);
    return null;
  }
};

// Test QR detection capability
window.testQRDetection = function() {
  return typeof jsQR !== 'undefined';
};