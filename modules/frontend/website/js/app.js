/**
 * Bedrock Fitness Chatbot Frontend Application
 * 
 * Main JavaScript application for the fitness chatbot frontend.
 * Handles authentication, chat functionality, and UI interactions.
 */

class BedrockChatbot {
    constructor() {
        this.config = window.APP_CONFIG || {};
        this.sessionId = null;
        this.isAuthenticated = false;
        this.userInfo = null;
        this.isTyping = false;
        
        // Initialize the application
        this.init();
    }
    
    async init() {
        console.log('Initializing Bedrock Chatbot...', this.config);
        
        try {
            // Check authentication status
            await this.checkAuthentication();
            
            if (this.isAuthenticated) {
                // User is authenticated, show the app
                this.showApp();
                this.setupEventListeners();
                this.generateSessionId();
            } else {
                // Redirect to authentication
                this.redirectToAuth();
            }
        } catch (error) {
            console.error('Initialization error:', error);
            this.showError('Failed to initialize the application. Please refresh the page.');
        }
    }
    
    async checkAuthentication() {
        // Check for authentication token in URL (OAuth callback)
        const urlParams = new URLSearchParams(window.location.search);
        const code = urlParams.get('code');
        const state = urlParams.get('state');
        
        if (code && state) {
            // Handle OAuth callback
            console.log('Handling OAuth callback...');
            await this.handleAuthCallback(code, state);
            return;
        }
        
        // Check for existing token in localStorage
        const token = localStorage.getItem('access_token');
        const userInfo = localStorage.getItem('user_info');
        
        if (token && userInfo) {
            try {
                // Validate token by making a test API call
                const isValid = await this.validateToken(token);
                if (isValid) {
                    this.isAuthenticated = true;
                    this.userInfo = JSON.parse(userInfo);
                    return;
                }
            } catch (error) {
                console.error('Token validation failed:', error);
            }
            
            // Token is invalid, remove it
            localStorage.removeItem('access_token');
            localStorage.removeItem('user_info');
        }
        
        this.isAuthenticated = false;
    }
    
    async handleAuthCallback(code, state) {
        try {
            // Verify state parameter (should match what we sent)
            const storedState = sessionStorage.getItem('oauth_state');
            if (state !== storedState) {
                throw new Error('Invalid state parameter');
            }
            
            // Exchange authorization code for tokens
            const tokenResponse = await this.exchangeCodeForTokens(code);
            
            // Store tokens
            localStorage.setItem('access_token', tokenResponse.access_token);
            localStorage.setItem('refresh_token', tokenResponse.refresh_token);
            
            // Get user info from token
            const userInfo = this.parseJwtToken(tokenResponse.access_token);
            localStorage.setItem('user_info', JSON.stringify(userInfo));
            
            this.isAuthenticated = true;
            this.userInfo = userInfo;
            
            // Clean up URL and storage
            sessionStorage.removeItem('oauth_state');
            window.history.replaceState({}, document.title, window.location.pathname);
            
        } catch (error) {
            console.error('Auth callback error:', error);
            this.showError('Authentication failed. Please try again.');
        }
    }
    
    async exchangeCodeForTokens(code) {
        // In a real implementation, this would exchange the code for tokens
        // via the Identity Center token endpoint. For this demo, we'll simulate it.
        
        const tokenEndpoint = `${this.config.IDENTITY_CENTER_ISSUER_URL}/oauth2/token`;
        
        const tokenData = {
            grant_type: 'authorization_code',
            client_id: this.config.IDENTITY_CENTER_CLIENT_ID,
            code: code,
            redirect_uri: `${this.config.WEBSITE_URL}/callback`
        };
        
        const response = await fetch(tokenEndpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: new URLSearchParams(tokenData)
        });
        
        if (!response.ok) {
            throw new Error('Token exchange failed');
        }
        
        return await response.json();
    }
    
    parseJwtToken(token) {
        try {
            const payload = token.split('.')[1];
            const decoded = JSON.parse(atob(payload));
            
            return {
                userId: decoded.sub,
                email: decoded.email,
                name: decoded.name || decoded.email,
                username: decoded.username,
                groups: decoded['custom:groups'] || []
            };
        } catch (error) {
            console.error('Error parsing JWT:', error);
            return null;
        }
    }
    
    async validateToken(token) {
        try {
            // Make a test call to the health endpoint
            const response = await fetch(`${this.config.API_URL}/health`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });
            
            return response.ok;
        } catch (error) {
            console.error('Token validation error:', error);
            return false;
        }
    }
    
    redirectToAuth() {
        // Generate state parameter for security
        const state = this.generateRandomString(32);
        sessionStorage.setItem('oauth_state', state);
        
        // Build authorization URL
        const authUrl = new URL(`${this.config.IDENTITY_CENTER_ISSUER_URL}/oauth2/authorize`);
        authUrl.searchParams.set('response_type', 'code');
        authUrl.searchParams.set('client_id', this.config.IDENTITY_CENTER_CLIENT_ID);
        authUrl.searchParams.set('redirect_uri', `${this.config.WEBSITE_URL}/callback`);
        authUrl.searchParams.set('scope', 'openid profile email');
        authUrl.searchParams.set('state', state);
        
        console.log('Redirecting to auth:', authUrl.toString());
        window.location.href = authUrl.toString();
    }
    
    showApp() {
        // Hide loading screen and show app
        document.getElementById('loading-screen').style.display = 'none';
        document.getElementById('app').style.display = 'flex';
        
        // Update user info in UI
        if (this.userInfo) {
            const userNameElement = document.getElementById('user-name');
            if (userNameElement) {
                userNameElement.textContent = this.userInfo.name || this.userInfo.email;
            }
        }
    }
    
    setupEventListeners() {
        // Chat form submission
        const chatForm = document.getElementById('chat-form');
        const messageInput = document.getElementById('message-input');
        const sendBtn = document.getElementById('send-btn');
        const charCount = document.getElementById('char-count');
        
        if (chatForm) {
            chatForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.sendMessage();
            });
        }
        
        if (messageInput) {
            // Auto-resize textarea
            messageInput.addEventListener('input', (e) => {
                this.updateCharacterCount();
                this.autoResizeTextarea(e.target);
                this.updateSendButton();
            });
            
            // Handle Enter key
            messageInput.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    if (messageInput.value.trim()) {
                        this.sendMessage();
                    }
                }
            });
        }
        
        // Logout button
        const logoutBtn = document.getElementById('logout-btn');
        if (logoutBtn) {
            logoutBtn.addEventListener('click', () => {
                this.logout();
            });
        }
        
        // Error modal
        const errorModalClose = document.getElementById('error-modal-close');
        const errorModalOk = document.getElementById('error-modal-ok');
        
        if (errorModalClose) {
            errorModalClose.addEventListener('click', () => {
                this.hideError();
            });
        }
        
        if (errorModalOk) {
            errorModalOk.addEventListener('click', () => {
                this.hideError();
            });
        }
        
        // Initial character count and button state
        this.updateCharacterCount();
        this.updateSendButton();
    }
    
    updateCharacterCount() {
        const messageInput = document.getElementById('message-input');
        const charCount = document.getElementById('char-count');
        
        if (messageInput && charCount) {
            const count = messageInput.value.length;
            charCount.textContent = count;
            
            // Change color when approaching limit
            if (count > 3800) {
                charCount.style.color = 'var(--error-color)';
            } else if (count > 3500) {
                charCount.style.color = 'var(--warning-color)';
            } else {
                charCount.style.color = 'var(--text-muted)';
            }
        }
    }
    
    updateSendButton() {
        const messageInput = document.getElementById('message-input');
        const sendBtn = document.getElementById('send-btn');
        
        if (messageInput && sendBtn) {
            const hasText = messageInput.value.trim().length > 0;
            sendBtn.disabled = !hasText || this.isTyping;
        }
    }
    
    autoResizeTextarea(textarea) {
        textarea.style.height = 'auto';
        textarea.style.height = Math.min(textarea.scrollHeight, 120) + 'px';
    }
    
    async sendMessage() {
        const messageInput = document.getElementById('message-input');
        const message = messageInput.value.trim();
        
        if (!message || this.isTyping) {
            return;
        }
        
        // Add user message to chat
        this.addMessage(message, 'user');
        
        // Clear input and reset height
        messageInput.value = '';
        messageInput.style.height = 'auto';
        this.updateCharacterCount();
        this.updateSendButton();
        
        // Show typing indicator
        this.showTypingIndicator();
        
        try {
            // Send message to API
            const response = await this.callChatAPI(message);
            
            // Hide typing indicator
            this.hideTypingIndicator();
            
            // Add assistant response
            this.addMessage(response.response, 'assistant');
            
            // Update session ID if provided
            if (response.sessionId) {
                this.sessionId = response.sessionId;
            }
            
        } catch (error) {
            console.error('Chat API error:', error);
            this.hideTypingIndicator();
            this.addMessage('I apologize, but I encountered an error processing your request. Please try again.', 'assistant');
        }
    }
    
    async callChatAPI(message) {
        const token = localStorage.getItem('access_token');
        
        const requestBody = {
            message: message,
            sessionId: this.sessionId
        };
        
        const response = await fetch(`${this.config.API_URL}/chat`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(requestBody)
        });
        
        if (!response.ok) {
            if (response.status === 401) {
                // Token expired, redirect to auth
                this.logout();
                return;
            }
            
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.error || `HTTP ${response.status}`);
        }
        
        return await response.json();
    }
    
    addMessage(content, type) {
        const chatMessages = document.getElementById('chat-messages');
        if (!chatMessages) return;
        
        const messageElement = document.createElement('div');
        messageElement.className = `message ${type}-message`;
        
        const avatar = document.createElement('div');
        avatar.className = 'message-avatar';
        avatar.textContent = type === 'user' ? '👤' : '🤖';
        
        const messageContent = document.createElement('div');
        messageContent.className = 'message-content';
        
        // Process content for basic formatting
        const formattedContent = this.formatMessageContent(content);
        messageContent.innerHTML = formattedContent;
        
        messageElement.appendChild(avatar);
        messageElement.appendChild(messageContent);
        
        chatMessages.appendChild(messageElement);
        
        // Scroll to bottom
        chatMessages.scrollTop = chatMessages.scrollHeight;
    }
    
    formatMessageContent(content) {
        // Basic formatting for lists and line breaks
        return content
            .replace(/\n/g, '<br>')
            .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
            .replace(/\*(.*?)\*/g, '<em>$1</em>')
            .replace(/`(.*?)`/g, '<code>$1</code>');
    }
    
    showTypingIndicator() {
        this.isTyping = true;
        this.updateSendButton();
        
        const typingIndicator = document.getElementById('typing-indicator');
        if (typingIndicator) {
            typingIndicator.style.display = 'flex';
            
            // Scroll to bottom
            const chatMessages = document.getElementById('chat-messages');
            if (chatMessages) {
                chatMessages.scrollTop = chatMessages.scrollHeight;
            }
        }
    }
    
    hideTypingIndicator() {
        this.isTyping = false;
        this.updateSendButton();
        
        const typingIndicator = document.getElementById('typing-indicator');
        if (typingIndicator) {
            typingIndicator.style.display = 'none';
        }
    }
    
    showError(message) {
        const errorModal = document.getElementById('error-modal');
        const errorMessage = document.getElementById('error-message');
        
        if (errorModal && errorMessage) {
            errorMessage.textContent = message;
            errorModal.style.display = 'flex';
        }
    }
    
    hideError() {
        const errorModal = document.getElementById('error-modal');
        if (errorModal) {
            errorModal.style.display = 'none';
        }
    }
    
    logout() {
        // Clear stored tokens and user info
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        localStorage.removeItem('user_info');
        sessionStorage.clear();
        
        // Redirect to logout URL or home
        const logoutUrl = `${this.config.IDENTITY_CENTER_ISSUER_URL}/oauth2/logout?client_id=${this.config.IDENTITY_CENTER_CLIENT_ID}&logout_uri=${encodeURIComponent(this.config.WEBSITE_URL)}`;
        window.location.href = logoutUrl;
    }
    
    generateSessionId() {
        this.sessionId = this.generateRandomString(16);
    }
    
    generateRandomString(length) {
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        let result = '';
        for (let i = 0; i < length; i++) {
            result += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return result;
    }
}

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    try {
        window.chatbot = new BedrockChatbot();
    } catch (error) {
        console.error('Failed to initialize chatbot:', error);
        
        // Show error message
        document.getElementById('loading-screen').innerHTML = `
            <div style="text-align: center; color: var(--error-color);">
                <h3>Initialization Error</h3>
                <p>Failed to start the application. Please refresh the page.</p>
                <button onclick="window.location.reload()" style="margin-top: 1rem; padding: 0.5rem 1rem; background: var(--primary-color); color: white; border: none; border-radius: 4px; cursor: pointer;">
                    Refresh Page
                </button>
            </div>
        `;
    }
});

// Handle browser back/forward navigation
window.addEventListener('popstate', (event) => {
    if (window.chatbot && window.chatbot.isAuthenticated) {
        // Handle client-side routing if needed
        console.log('Navigation event:', event);
    }
});

// Handle online/offline status
window.addEventListener('online', () => {
    console.log('Application is back online');
});

window.addEventListener('offline', () => {
    console.log('Application is offline');
    if (window.chatbot) {
        window.chatbot.showError('You appear to be offline. Please check your internet connection.');
    }
});