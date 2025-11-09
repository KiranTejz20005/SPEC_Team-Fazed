// Navigation function
function navigateTo(screenId) {
    // Hide all screens
    const screens = document.querySelectorAll('.screen');
    screens.forEach(screen => {
        screen.classList.remove('active');
    });

    // Show target screen
    const targetScreen = document.getElementById(screenId);
    if (targetScreen) {
        targetScreen.classList.add('active');
        window.scrollTo(0, 0);
    } else {
        // If screen doesn't exist in current page, navigate to appropriate page
        const pageMap = {
            'dashboard': 'index.html',
            'form-selection': 'form-selection.html',
            'document-upload': 'document-upload.html',
            'conversational-form': 'conversational-form.html',
            'review': 'review.html',
            'settings': 'settings.html',
            'templates': 'templates.html',
            'history': 'history.html'
        };

        if (pageMap[screenId]) {
            window.location.href = pageMap[screenId];
        }
    }
}

// Carousel functionality for onboarding
document.addEventListener('DOMContentLoaded', function() {
    // Feature carousel
    const carouselItems = document.querySelectorAll('.carousel-item');
    const dots = document.querySelectorAll('.dot');
    let currentIndex = 0;

    function showCarouselItem(index) {
        carouselItems.forEach((item, i) => {
            item.classList.toggle('active', i === index);
        });
        dots.forEach((dot, i) => {
            dot.classList.toggle('active', i === index);
        });
    }

    dots.forEach((dot, index) => {
        dot.addEventListener('click', () => {
            currentIndex = index;
            showCarouselItem(currentIndex);
        });
    });

    // Auto-advance carousel
    setInterval(() => {
        currentIndex = (currentIndex + 1) % carouselItems.length;
        showCarouselItem(currentIndex);
    }, 4000);

    // Accordion functionality for review screen
    const accordionHeaders = document.querySelectorAll('.accordion-header');
    accordionHeaders.forEach(header => {
        header.addEventListener('click', () => {
            const accordion = header.parentElement;
            const content = accordion.querySelector('.accordion-content');
            const arrow = header.querySelector('.accordion-arrow');
            
            content.classList.toggle('active');
            arrow.style.transform = content.classList.contains('active') 
                ? 'rotate(180deg)' 
                : 'rotate(0deg)';
        });
    });

    // File upload functionality
    const uploadArea = document.getElementById('uploadArea');
    const fileInput = document.getElementById('fileInput');
    
    if (uploadArea && fileInput) {
        uploadArea.addEventListener('click', () => {
            fileInput.click();
        });

        uploadArea.addEventListener('dragover', (e) => {
            e.preventDefault();
            uploadArea.style.borderColor = 'var(--primary-color)';
            uploadArea.style.background = '#F0F7FF';
        });

        uploadArea.addEventListener('dragleave', () => {
            uploadArea.style.borderColor = 'var(--border-color)';
            uploadArea.style.background = '#FAFAFA';
        });

        uploadArea.addEventListener('drop', (e) => {
            e.preventDefault();
            uploadArea.style.borderColor = 'var(--border-color)';
            uploadArea.style.background = '#FAFAFA';
            
            const files = e.dataTransfer.files;
            handleFiles(files);
        });

        fileInput.addEventListener('change', (e) => {
            handleFiles(e.target.files);
        });
    }

    function handleFiles(files) {
        // In a real app, this would upload files to a server
        console.log('Files selected:', files);
        // You could show a notification or update the UI here
    }

    // Chat functionality
    const chatInput = document.querySelector('.chat-input');
    const sendButton = document.querySelector('.send-button');
    const chatMessages = document.getElementById('chatMessages');

    if (chatInput && sendButton && chatMessages) {
        function sendMessage() {
            const message = chatInput.value.trim();
            if (message) {
                // Add user message
                const userMessage = document.createElement('div');
                userMessage.className = 'message user-message';
                userMessage.innerHTML = `
                    <div class="message-content">
                        <div class="message-bubble">${message}</div>
                        <div class="message-time">${new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</div>
                    </div>
                `;
                chatMessages.appendChild(userMessage);
                chatInput.value = '';

                // Scroll to bottom
                chatMessages.scrollTop = chatMessages.scrollHeight;

                // Simulate AI response
                setTimeout(() => {
                    const typingMessage = document.createElement('div');
                    typingMessage.className = 'message ai-message typing';
                    typingMessage.innerHTML = `
                        <div class="message-avatar">🤖</div>
                        <div class="message-content">
                            <div class="message-bubble">
                                <div class="typing-indicator">
                                    <span></span>
                                    <span></span>
                                    <span></span>
                                </div>
                            </div>
                        </div>
                    `;
                    chatMessages.appendChild(typingMessage);
                    chatMessages.scrollTop = chatMessages.scrollHeight;

                    setTimeout(() => {
                        typingMessage.remove();
                        const aiMessage = document.createElement('div');
                        aiMessage.className = 'message ai-message';
                        aiMessage.innerHTML = `
                            <div class="message-avatar">🤖</div>
                            <div class="message-content">
                                <div class="message-bubble">I understand. Let me help you with that!</div>
                                <div class="message-time">${new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</div>
                            </div>
                        `;
                        chatMessages.appendChild(aiMessage);
                        chatMessages.scrollTop = chatMessages.scrollHeight;
                    }, 1500);
                }, 500);
            }
        }

        sendButton.addEventListener('click', sendMessage);
        chatInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                sendMessage();
            }
        });
    }

    // Quick action buttons in chat
    const quickActions = document.querySelectorAll('.quick-action');
    quickActions.forEach(button => {
        button.addEventListener('click', () => {
            const action = button.textContent;
            if (chatInput) {
                chatInput.value = action;
                if (sendButton) {
                    sendButton.click();
                }
            }
        });
    });

    // Filter functionality
    const filterChips = document.querySelectorAll('.filter-chip');
    filterChips.forEach(chip => {
        chip.addEventListener('click', () => {
            filterChips.forEach(c => c.classList.remove('active'));
            chip.classList.add('active');
        });
    });

    const filterBtns = document.querySelectorAll('.filter-btn');
    filterBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            filterBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
        });
    });

    // Toggle switches
    const toggles = document.querySelectorAll('.toggle-switch input');
    toggles.forEach(toggle => {
        toggle.addEventListener('change', (e) => {
            console.log('Toggle changed:', e.target.checked);
            // In a real app, this would save the preference
        });
    });

    // Template use buttons
    const templateUseBtns = document.querySelectorAll('.template-use-btn, .featured-use-btn');
    templateUseBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            navigateTo('form-selection');
        });
    });

    // Form card click handlers
    const formCards = document.querySelectorAll('.form-card');
    formCards.forEach(card => {
        card.addEventListener('click', () => {
            navigateTo('conversational-form');
        });
    });

    // History action buttons
    const historyActionBtns = document.querySelectorAll('.history-item .action-btn');
    historyActionBtns.forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            const action = btn.textContent.trim();
            if (action.includes('Continue')) {
                navigateTo('conversational-form');
            } else if (action.includes('View')) {
                navigateTo('review');
            }
            // Other actions would be handled here
        });
    });

    // Smooth scroll for chat messages
    if (chatMessages) {
        chatMessages.scrollTop = chatMessages.scrollHeight;
    }
});

// Handle back button navigation
window.addEventListener('popstate', function(event) {
    // Handle browser back/forward buttons
    const currentPath = window.location.pathname;
    const screenId = currentPath.split('/').pop().replace('.html', '');
    if (screenId && screenId !== 'index') {
        navigateTo(screenId);
    }
});

// Initialize current screen based on URL
document.addEventListener('DOMContentLoaded', function() {
    const currentPath = window.location.pathname;
    const fileName = currentPath.split('/').pop();
    
    // Load saved theme - applyTheme should be available globally from auth.js
    if (typeof applyTheme === 'function') {
        const savedTheme = localStorage.getItem('fillora-theme') || 'light';
        applyTheme(savedTheme);
    } else {
        // Fallback: apply theme class directly if function not available
        const savedTheme = localStorage.getItem('fillora-theme') || 'light';
        const themeClasses = ['theme-light', 'theme-dark', 'theme-blue', 'theme-green', 'theme-purple', 'theme-orange', 'theme-pink'];
        document.body.classList.remove(...themeClasses);
        document.body.classList.add(`theme-${savedTheme}`);
    }
    
    if (fileName === 'index.html' || fileName === '' || fileName === 'index.html') {
        navigateTo('dashboard');
    } else {
        const screenId = fileName.replace('.html', '');
        navigateTo(screenId);
    }
});
