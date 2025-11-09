// Mobile Navigation Toggle
const navToggle = document.querySelector('.nav-toggle');
const navMenu = document.querySelector('.nav-menu');

if (navToggle) {
    navToggle.addEventListener('click', () => {
        navMenu.classList.toggle('active');
    });

    // Close menu when clicking on a link
    document.querySelectorAll('.nav-menu a').forEach(link => {
        link.addEventListener('click', () => {
            navMenu.classList.remove('active');
        });
    });
}

// Smooth scrolling for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Screenshot Grid - Lightbox functionality (optional enhancement)
const screenshotItems = document.querySelectorAll('.screenshot-grid-item');
screenshotItems.forEach(item => {
    item.addEventListener('click', () => {
        const img = item.querySelector('img');
        if (img) {
            // Optional: Open image in lightbox or fullscreen
            console.log('Screenshot clicked:', img.alt);
        }
    });
});

// QR Code Generation
function generateQRCode() {
    const canvas = document.getElementById('qrCode');
    if (!canvas) return;

    // Get the download URL (update this with your actual APK URL)
    const downloadUrl = document.getElementById('downloadBtn')?.href || 
                       'https://www.upload-apk.com/Sv3n0Ecf8qkPP2m';
    
    // Use a simple QR code library or API
    // For now, we'll use a simple approach with qrcode.js library
    // You can also use an online QR code API
    
    // Simple QR code using an API
    const qrSize = 200;
    const qrApiUrl = `https://api.qrserver.com/v1/create-qr-code/?size=${qrSize}x${qrSize}&data=${encodeURIComponent(downloadUrl)}`;
    
    // Create an image element
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = function() {
        const ctx = canvas.getContext('2d');
        canvas.width = qrSize;
        canvas.height = qrSize;
        ctx.drawImage(img, 0, 0);
    };
    img.onerror = function() {
        // Fallback: Draw a placeholder
        const ctx = canvas.getContext('2d');
        canvas.width = qrSize;
        canvas.height = qrSize;
        ctx.fillStyle = '#FFFFFF';
        ctx.fillRect(0, 0, qrSize, qrSize);
        ctx.fillStyle = '#000000';
        ctx.font = '16px Arial';
        ctx.textAlign = 'center';
        ctx.fillText('QR Code', qrSize / 2, qrSize / 2 - 10);
        ctx.fillText('Placeholder', qrSize / 2, qrSize / 2 + 10);
    };
    img.src = qrApiUrl;
}

// Initialize QR code when page loads
document.addEventListener('DOMContentLoaded', generateQRCode);

// Download Button Handler
const downloadBtn = document.getElementById('downloadBtn');
if (downloadBtn) {
    // Update this URL with your actual APK hosting URL
    downloadBtn.href = 'https://www.upload-apk.com/Sv3n0Ecf8qkPP2m';
    
    downloadBtn.addEventListener('click', (e) => {
        // You can add analytics tracking here
        console.log('Download button clicked');
        // The download will proceed normally via the href
    });
}

// Scroll animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Observe elements for animation
document.addEventListener('DOMContentLoaded', () => {
    const animatedElements = document.querySelectorAll('.feature-card, .step-item, .language-item, .screenshot-card');
    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(20px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
});

// Navbar scroll effect
let lastScroll = 0;
const navbar = document.querySelector('.navbar');

window.addEventListener('scroll', () => {
    const currentScroll = window.pageYOffset;
    
    if (currentScroll <= 0) {
        navbar.style.boxShadow = 'none';
    } else {
        navbar.style.boxShadow = '0 2px 10px rgba(0, 0, 0, 0.1)';
    }
    
    lastScroll = currentScroll;
});

// Form validation (if contact form exists)
const contactForm = document.querySelector('#contactForm');
if (contactForm) {
    contactForm.addEventListener('submit', (e) => {
        e.preventDefault();
        // Add form submission logic here
        alert('Thank you for your message! We will get back to you soon.');
        contactForm.reset();
    });
}

