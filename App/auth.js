// Apply theme function - MUST be defined globally FIRST
function applyTheme(themeName) {
    if (!themeName) return;
    
    // Remove all existing theme classes
    const themeClasses = ['theme-light', 'theme-dark', 'theme-blue', 'theme-green', 'theme-purple', 'theme-orange', 'theme-pink'];
    document.body.classList.remove(...themeClasses);
    
    // Add new theme class
    document.body.classList.add(`theme-${themeName}`);
    
    // Save to localStorage
    localStorage.setItem('fillora-theme', themeName);
    
    // Update all theme options active state (floating selector)
    const themeOptions = document.querySelectorAll('.theme-option');
    themeOptions.forEach(opt => {
        opt.classList.remove('active');
        if (opt.getAttribute('data-theme') === themeName) {
            opt.classList.add('active');
        }
    });
    
    // Update all theme options active state (settings page)
    const themeOptionsSmall = document.querySelectorAll('.theme-option-small');
    themeOptionsSmall.forEach(opt => {
        opt.classList.remove('active');
        if (opt.getAttribute('data-theme') === themeName) {
            opt.classList.add('active');
        }
    });
    
    console.log('Theme applied:', themeName);
}

// Initialize theme on page load (immediate execution)
(function() {
    const savedTheme = localStorage.getItem('fillora-theme') || 'light';
    if (document.body) {
        // Wait for body to be ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', function() {
                applyTheme(savedTheme);
            });
        } else {
            applyTheme(savedTheme);
        }
    }
})();

// Authentication and Theme Management
document.addEventListener('DOMContentLoaded', function() {
    // Load saved theme on DOM ready
    const savedTheme = localStorage.getItem('fillora-theme') || 'light';
    applyTheme(savedTheme);

    // Password toggle functionality
    const passwordToggles = document.querySelectorAll('.password-toggle');
    passwordToggles.forEach(toggle => {
        toggle.addEventListener('click', function() {
            const input = this.previousElementSibling || this.parentElement.querySelector('input[type="password"], input[type="text"]');
            if (input.type === 'password') {
                input.type = 'text';
                this.textContent = '🙈';
            } else {
                input.type = 'password';
                this.textContent = '👁️';
            }
        });
    });

    // Password strength indicator
    const passwordInput = document.getElementById('signupPasswordInput');
    if (passwordInput) {
        const strengthFill = document.getElementById('strengthFill');
        const strengthText = document.getElementById('strengthText');
        
        passwordInput.addEventListener('input', function() {
            const password = this.value;
            const strength = calculatePasswordStrength(password);
            
            if (strengthFill) {
                strengthFill.style.width = strength.percentage + '%';
                strengthFill.style.background = strength.color;
            }
            
            if (strengthText) {
                strengthText.textContent = strength.text;
                strengthText.style.color = strength.color;
            }
        });
    }

    function calculatePasswordStrength(password) {
        let strength = 0;
        let feedback = [];
        
        if (password.length >= 8) strength += 25;
        else feedback.push('at least 8 characters');
        
        if (/[a-z]/.test(password)) strength += 25;
        else feedback.push('lowercase letters');
        
        if (/[A-Z]/.test(password)) strength += 25;
        else feedback.push('uppercase letters');
        
        if (/[0-9]/.test(password)) strength += 15;
        else feedback.push('numbers');
        
        if (/[^a-zA-Z0-9]/.test(password)) strength += 10;
        else feedback.push('special characters');
        
        let text, color;
        if (strength < 30) {
            text = 'Weak password';
            color = '#EF4444';
        } else if (strength < 60) {
            text = 'Fair password';
            color = '#F59E0B';
        } else if (strength < 80) {
            text = 'Good password';
            color = '#3B82F6';
        } else {
            text = 'Strong password';
            color = '#10B981';
        }
        
        return {
            percentage: strength,
            text: text,
            color: color
        };
    }

    // Form submission handlers
    const signInForm = document.getElementById('signInForm');
    if (signInForm) {
        signInForm.addEventListener('submit', function(e) {
            e.preventDefault();
            // Simulate sign in
            const button = this.querySelector('.auth-button');
            const originalText = button.innerHTML;
            button.innerHTML = '<span>Signing in...</span>';
            button.disabled = true;
            
            setTimeout(() => {
                window.location.href = 'index.html#dashboard';
            }, 1500);
        });
    }

    const signUpForm = document.getElementById('signUpForm');
    if (signUpForm) {
        signUpForm.addEventListener('submit', function(e) {
            e.preventDefault();
            // Simulate sign up
            const button = this.querySelector('.auth-button');
            const originalText = button.innerHTML;
            button.innerHTML = '<span>Creating account...</span>';
            button.disabled = true;
            
            setTimeout(() => {
                window.location.href = 'index.html#dashboard';
            }, 1500);
        });
    }

    // Initialize Facebook SDK
    window.fbAsyncInit = function() {
        FB.init({
            appId: 'YOUR_FACEBOOK_APP_ID', // Replace with your Facebook App ID
            cookie: true,
            xfbml: true,
            version: 'v18.0'
        });
    };

    // Google Sign-In Configuration
    window.onGoogleLibraryLoad = function() {
        google.accounts.id.initialize({
            client_id: '856180854835-mvgr9ma94ujukg7ii1b1qcc24letp6o9.apps.googleusercontent.com',
            callback: handleGoogleSignIn
        });
    };

    // Google Sign-In Handler
    window.handleGoogleSignIn = function(response) {
        try {
            // Decode the JWT token
            const base64Url = response.credential.split('.')[1];
            const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
            const jsonPayload = decodeURIComponent(atob(base64).split('').map(function(c) {
                return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
            }).join(''));

            const userData = JSON.parse(jsonPayload);
            
            // Save user data
            localStorage.setItem('fillora_user', JSON.stringify({
                provider: 'google',
                id: userData.sub,
                email: userData.email,
                name: userData.name,
                picture: userData.picture,
                idToken: response.credential
            }));
            localStorage.setItem('fillora_auth_provider', 'google');
            localStorage.setItem('fillora_is_signed_in', 'true');

            // Show success message
            showNotification('Signed in with Google successfully!', 'success');
            
            // Redirect to dashboard
            setTimeout(() => {
                window.location.href = 'index.html#dashboard';
            }, 1000);
        } catch (error) {
            console.error('Error processing Google sign-in:', error);
            showNotification('Error signing in with Google. Please try again.', 'error');
        }
    };

    // Facebook Sign-In Handler
    function handleFacebookSignIn() {
        FB.login(function(response) {
            if (response.authResponse) {
                // User logged in successfully
                FB.api('/me', {fields: 'id,name,email,picture'}, function(userInfo) {
                    // Save user data
                    localStorage.setItem('fillora_user', JSON.stringify({
                        provider: 'facebook',
                        id: userInfo.id,
                        email: userInfo.email || '',
                        name: userInfo.name,
                        picture: userInfo.picture?.data?.url || '',
                        accessToken: response.authResponse.accessToken
                    }));
                    localStorage.setItem('fillora_auth_provider', 'facebook');
                    localStorage.setItem('fillora_is_signed_in', 'true');

                    // Show success message
                    showNotification('Signed in with Facebook successfully!', 'success');
                    
                    // Redirect to dashboard
                    setTimeout(() => {
                        window.location.href = 'index.html#dashboard';
                    }, 1000);
                });
            } else {
                // User cancelled login or did not fully authorize
                if (response.status !== 'unknown') {
                    showNotification('Facebook sign-in was cancelled.', 'info');
                }
            }
        }, {scope: 'email,public_profile'});
    }

    // Social sign in buttons
    const googleSignInBtn = document.getElementById('googleSignInBtn');
    const facebookSignInBtn = document.getElementById('facebookSignInBtn');

    if (googleSignInBtn) {
        googleSignInBtn.addEventListener('click', function() {
            // Trigger Google Sign-In
            google.accounts.id.prompt((notification) => {
                if (notification.isNotDisplayed() || notification.isSkippedMoment()) {
                    // Fallback: use One Tap
                    google.accounts.oauth2.initTokenClient({
                        client_id: '856180854835-mvgr9ma94ujukg7ii1b1qcc24letp6o9.apps.googleusercontent.com',
                        scope: 'email profile',
                        callback: (response) => {
                            if (response.access_token) {
                                // Get user info
                                fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
                                    headers: {
                                        'Authorization': `Bearer ${response.access_token}`
                                    }
                                })
                                .then(res => res.json())
                                .then(userData => {
                                    localStorage.setItem('fillora_user', JSON.stringify({
                                        provider: 'google',
                                        id: userData.id,
                                        email: userData.email,
                                        name: userData.name,
                                        picture: userData.picture,
                                        accessToken: response.access_token
                                    }));
                                    localStorage.setItem('fillora_auth_provider', 'google');
                                    localStorage.setItem('fillora_is_signed_in', 'true');
                                    
                                    showNotification('Signed in with Google successfully!', 'success');
                                    setTimeout(() => {
                                        window.location.href = 'index.html#dashboard';
                                    }, 1000);
                                });
                            }
                        }
                    }).requestAccessToken();
                }
            });
        });
    }

    if (facebookSignInBtn) {
        facebookSignInBtn.addEventListener('click', function() {
            handleFacebookSignIn();
        });
    }

    // Helper function to show notifications
    function showNotification(message, type) {
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.textContent = message;
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 16px 24px;
            background: ${type === 'success' ? '#10B981' : type === 'error' ? '#EF4444' : '#3B82F6'};
            color: white;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            z-index: 10000;
            animation: slideIn 0.3s ease-out;
        `;
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.style.animation = 'slideOut 0.3s ease-out';
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    }

    // Theme selection in settings page (ONLY way to change theme)
    const themeOptionsPreview = document.querySelectorAll('.theme-option-small');
    if (themeOptionsPreview.length > 0) {
        themeOptionsPreview.forEach(option => {
            // Set initial active state
            if (option.getAttribute('data-theme') === savedTheme) {
                option.classList.add('active');
            }
            
            // Add click handler
            option.addEventListener('click', function(e) {
                e.stopPropagation();
                const theme = this.getAttribute('data-theme');
                if (theme) {
                    applyTheme(theme);
                }
            });
        });
    }
});