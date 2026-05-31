const CHAT_MESSAGES_STORAGE_KEY = 'chatMessages';
const UNSAFE_MARKDOWN_TAGS = new Set([
    'base',
    'button',
    'embed',
    'form',
    'iframe',
    'input',
    'link',
    'meta',
    'object',
    'option',
    'script',
    'select',
    'style',
    'textarea'
]);

let chatMessagesHistory = [];

function appendMessage(message, type) {
    const chatMessages = document.getElementById('chatbox-messages');
    const messageElement = document.createElement('div');
    messageElement.classList.add('chat-bubble', type);

    messageElement.appendChild(renderMessageContent(message, type));

    chatMessages.appendChild(messageElement);
    chatMessagesHistory.push({ message, type });
    saveChatMessages();

    // Scroll to the bottom of the chatbox to show the latest message
    chatMessages.scrollTop = chatMessages.scrollHeight;
}

function renderMessageContent(message, type) {
    const messageText = message || '';

    if (type === 'user' || !window.marked) {
        const text = document.createElement('span');
        text.textContent = messageText;
        return text;
    }

    const template = document.createElement('template');
    template.innerHTML = marked.parse(escapeHtml(messageText));
    sanitizeMessageContent(template.content);

    const content = document.createElement('div');
    content.appendChild(template.content.cloneNode(true));
    return content;
}

function sanitizeMessageContent(content) {
    content.querySelectorAll('*').forEach(element => {
        const tagName = element.tagName.toLowerCase();

        if (UNSAFE_MARKDOWN_TAGS.has(tagName)) {
            element.remove();
            return;
        }

        [...element.attributes].forEach(attribute => {
            const name = attribute.name.toLowerCase();

            if (name.startsWith('on') || name === 'srcdoc') {
                element.removeAttribute(attribute.name);
                return;
            }

            if (name === 'style') {
                element.removeAttribute(attribute.name);
                return;
            }

            if ((name === 'href' || name === 'src' || name === 'xlink:href') && !isSafeUrl(attribute.value)) {
                element.removeAttribute(attribute.name);
            }
        });
    });
}

function escapeHtml(value) {
    return value
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function isSafeUrl(value) {
    const url = value.trim();

    if (!url) {
        return true;
    }

    try {
        const parsedUrl = new URL(url, window.location.origin);
        return ['http:', 'https:', 'mailto:', 'tel:'].includes(parsedUrl.protocol);
    } catch (error) {
        return false;
    }
}

function toggleChatbox() {
    const chatbox = document.getElementById('chatbox');
    const chatboxContent = document.getElementById('chatbox-content');

    if (chatbox.classList.contains('minimized')) {
        chatbox.classList.remove('minimized');
        chatboxContent.style.height = '400px'; // Set to initial height when expanded
    } else {
        chatbox.classList.add('minimized');
        chatboxContent.style.height = '40px'; // Set to minimized height
    }
}

function sendMessage() {
    const query = document.getElementById('chatbox-input').value;

    // Only send if there's a message
    if (!query.trim()) return;

    // Clear the input field after sending the message
    document.getElementById('chatbox-input').value = '';

    // Display user message in the chatbox
    appendMessage(query, 'user');

    // Send the message to the backend
    fetch('/api/genai/chatclient', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(query),
    })
        .then(response => response.text())
        .then(responseText => {
            // Display the response from the server in the chatbox
            appendMessage(responseText, 'bot');
        })
        .catch(error => {
            console.error('Error:', error);
            // Display the fallback message in the chatbox
            appendMessage('Chat is currently unavailable', 'bot');
        });
}

function handleKeyPress(event) {
    if (event.key === "Enter") {
        event.preventDefault(); // Prevents adding a newline
        sendMessage(); // Send the message when Enter is pressed
    }
}

// Save chat messages to localStorage
function saveChatMessages() {
    localStorage.setItem(CHAT_MESSAGES_STORAGE_KEY, JSON.stringify(chatMessagesHistory));
}

// Load chat messages from localStorage
function loadChatMessages() {
    const savedMessages = localStorage.getItem(CHAT_MESSAGES_STORAGE_KEY);

    if (!savedMessages) {
        return;
    }

    try {
        const parsedMessages = JSON.parse(savedMessages);

        if (!Array.isArray(parsedMessages)) {
            localStorage.removeItem(CHAT_MESSAGES_STORAGE_KEY);
            return;
        }

        parsedMessages
            .filter(({ message, type }) => typeof message === 'string' && ['bot', 'user'].includes(type))
            .forEach(({ message, type }) => appendMessage(message, type));
    } catch (error) {
        localStorage.removeItem(CHAT_MESSAGES_STORAGE_KEY);
    }
}
