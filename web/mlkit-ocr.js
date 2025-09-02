// Enhanced Google ML Kit Text Recognition for WebView
// This script provides OCR functionality using Google ML Kit with fallback to Tesseract

// Initialize Google ML Kit Text Recognition
let textRecognizer = null;

// Initialize ML Kit when available
function initializeMLKit() {
  try {
    if (typeof window.ml !== 'undefined' && window.ml.textRecognition) {
      textRecognizer = new window.ml.textRecognition.TextRecognizer();
      console.log('Google ML Kit Text Recognizer initialized');
      return true;
    }
  } catch (error) {
    console.warn('Failed to initialize Google ML Kit:', error);
  }
  return false;
}

// Enhanced Google ML Kit OCR processing
window.processImageWithGoogleMLKit = function(imagePath) {
  console.log('=== GOOGLE ML KIT OCR START ===');
  console.log('Processing image:', imagePath);
  
  return new Promise(async (resolve, reject) => {
    try {
      // Try to initialize ML Kit if not already done
      if (!textRecognizer && !initializeMLKit()) {
        console.log('Google ML Kit not available, using Tesseract fallback');
        return await fallbackToTesseract(imagePath, resolve);
      }
      
      // Load and process image
      const img = await loadImage(imagePath);
      const canvas = createCanvasFromImage(img);
      
      // Process with Google ML Kit
      const mlkitResult = await processWithMLKit(canvas);
      
      if (mlkitResult && mlkitResult.length > 0) {
        console.log('=== ML KIT SUCCESS ===');
        console.log('Extracted text length:', mlkitResult.length);
        resolve(mlkitResult);
      } else {
        console.log('ML Kit returned empty result, trying Tesseract');
        await fallbackToTesseract(imagePath, resolve);
      }
      
    } catch (error) {
      console.error('Google ML Kit processing failed:', error);
      await fallbackToTesseract(imagePath, resolve);
    }
  });
};

// Load image with proper error handling
function loadImage(imagePath) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    
    img.onload = () => resolve(img);
    img.onerror = () => reject(new Error('Failed to load image'));
    
    img.src = imagePath;
  });
}

// Create canvas from image with preprocessing
function createCanvasFromImage(img) {
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d');
  
  // Set canvas size
  canvas.width = img.width;
  canvas.height = img.height;
  
  // Draw image
  ctx.drawImage(img, 0, 0);
  
  // Apply image preprocessing for better OCR
  const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
  const data = imageData.data;
  
  // Convert to grayscale and enhance contrast
  for (let i = 0; i < data.length; i += 4) {
    const gray = Math.round(0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2]);
    
    // Apply contrast enhancement
    const contrast = 1.3;
    const factor = (259 * (contrast + 255)) / (255 * (259 - contrast));
    const enhanced = Math.max(0, Math.min(255, Math.round(factor * (gray - 128) + 128)));
    
    data[i] = enhanced;     // Red
    data[i + 1] = enhanced; // Green
    data[i + 2] = enhanced; // Blue
    // Alpha remains unchanged
  }
  
  // Put enhanced image back
  ctx.putImageData(imageData, 0, 0);
  
  return canvas;
}

// Process with Google ML Kit
async function processWithMLKit(canvas) {
  try {
    if (!textRecognizer) {
      throw new Error('ML Kit Text Recognizer not available');
    }
    
    // Convert canvas to ImageData
    const ctx = canvas.getContext('2d');
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    
    // Process with ML Kit
    const results = await textRecognizer.recognize(imageData);
    
    let extractedText = '';
    if (results && results.textBlocks) {
      for (const block of results.textBlocks) {
        if (block.lines) {
          for (const line of block.lines) {
            if (line.text) {
              extractedText += line.text + '\n';
            }
          }
        }
      }
    }
    
    // Clean and filter text
    const cleanText = cleanExtractedText(extractedText);
    
    console.log('=== ML KIT RAW TEXT ===');
    console.log(extractedText);
    console.log('=== ML KIT CLEAN TEXT ===');
    console.log(cleanText);
    
    return cleanText;
    
  } catch (error) {
    console.error('ML Kit processing error:', error);
    throw error;
  }
}

// Fallback to Tesseract OCR
async function fallbackToTesseract(imagePath, resolve) {
  console.log('=== TESSERACT FALLBACK ===');
  
  try {
    if (typeof Tesseract === 'undefined') {
      console.error('Tesseract not available');
      resolve('');
      return;
    }
    
    const { data: { text } } = await Tesseract.recognize(
      imagePath,
      'eng',
      {
        logger: m => {
          if (m.status === 'recognizing text') {
            console.log(`Tesseract Progress: ${Math.round(m.progress * 100)}%`);
          }
        }
      }
    );
    
    const cleanText = cleanExtractedText(text);
    
    console.log('=== TESSERACT RAW TEXT ===');
    console.log(text);
    console.log('=== TESSERACT CLEAN TEXT ===');
    console.log(cleanText);
    
    resolve(cleanText);
    
  } catch (error) {
    console.error('Tesseract fallback failed:', error);
    resolve('');
  }
}

// Clean extracted text
function cleanExtractedText(text) {
  if (!text) return '';
  
  // Remove Arabic/non-Latin characters
  let cleanText = text.replace(/[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]/g, ' ');
  
  // Normalize whitespace
  cleanText = cleanText.replace(/\s+/g, ' ').trim();
  
  // Remove common OCR artifacts
  cleanText = cleanText.replace(/[|\\]/g, ' ');
  cleanText = cleanText.replace(/\s+/g, ' ').trim();
  
  return cleanText;
}

// Enhanced Emirates ID data extraction
function extractEmiratesIdDataEnhanced(text) {
  console.log('=== ENHANCED EMIRATES ID EXTRACTION ===');
  
  const data = {};
  const lines = text.split('\n');
  
  // Enhanced name extraction
  const namePatterns = [
    /name[:\s]*([a-z\s]{3,50})/i,
    /holder[:\s]*([a-z\s]{3,50})/i,
    /^([A-Z][a-z]+\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)/m
  ];
  
  for (const pattern of namePatterns) {
    const match = text.match(pattern);
    if (match && !data.name) {
      data.name = match[1].trim();
      break;
    }
  }
  
  // Enhanced ID number extraction
  const idPatterns = [
    /784[-\s]*(\d{4})[-\s]*(\d{7})[-\s]*(\d)/g,
    /id[:\s]*784[-\s]*(\d{4})[-\s]*(\d{7})[-\s]*(\d)/gi
  ];
  
  for (const pattern of idPatterns) {
    const match = pattern.exec(text);
    if (match && !data.idNumber) {
      data.idNumber = `784-${match[1]}-${match[2]}-${match[3]}`;
      break;
    }
  }
  
  // Enhanced date extraction
  const datePattern = /(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})/g;
  const dates = [];
  let match;
  
  while ((match = datePattern.exec(text)) !== null) {
    const year = parseInt(match[3]);
    const date = `${match[1]}/${match[2]}/${match[3]}`;
    
    if (year >= 1950 && year <= 2010 && !data.dateOfBirth) {
      data.dateOfBirth = date;
    } else if (year >= 2020 && year <= 2035 && !data.expiryDate) {
      data.expiryDate = date;
    }
    
    dates.push(date);
  }
  
  // Enhanced nationality extraction
  const nationalityPattern = /\b(indian|pakistani|bangladeshi|filipino|egyptian|syrian|jordanian|lebanese|british|american|canadian)\b/i;
  const nationalityMatch = text.match(nationalityPattern);
  if (nationalityMatch) {
    data.nationality = nationalityMatch[1];
  }
  
  // Enhanced occupation extraction
  const occupationPattern = /occupation[:\s]*([a-z\s]{3,30})/i;
  const occupationMatch = text.match(occupationPattern);
  if (occupationMatch) {
    data.occupation = occupationMatch[1].trim();
  }
  
  console.log('Extracted Emirates ID data:', data);
  return data;
}

// Maintain backward compatibility
window.processImageWithMLKit = window.processImageWithGoogleMLKit;

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
  initializeMLKit();
});

console.log('Enhanced Google ML Kit OCR script loaded');