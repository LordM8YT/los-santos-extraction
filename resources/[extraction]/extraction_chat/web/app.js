const { useEffect, useRef, useState } = React;
const e = React.createElement;

const resourceName =
    typeof GetParentResourceName === 'function'
        ? GetParentResourceName()
        : 'extraction_chat';

function postNui(eventName, payload = {}) {
    return fetch(`https://${resourceName}/${eventName}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(payload),
    }).catch(() => undefined);
}

function normalizeSuggestion(suggestion) {
    if (!suggestion || typeof suggestion.name !== 'string') {
        return null;
    }

    return {
        name: suggestion.name,
        help: typeof suggestion.help === 'string' ? suggestion.help : '',
        params: Array.isArray(suggestion.params) ? suggestion.params : [],
    };
}

function normalizeMessage(message) {
    if (!message || typeof message.text !== 'string') {
        return null;
    }

    return {
        id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
        author: typeof message.author === 'string' && message.author.trim() !== '' ? message.author : 'SYSTEM',
        text: message.text,
        variant: typeof message.variant === 'string' ? message.variant : 'system',
    };
}

function App() {
    const inputRef = useRef(null);
    const [visible, setVisible] = useState(false);
    const [input, setInput] = useState('');
    const [messages, setMessages] = useState([]);
    const [suggestions, setSuggestions] = useState([]);
    const [selectedSuggestion, setSelectedSuggestion] = useState(0);
    const [history, setHistory] = useState([]);
    const [historyIndex, setHistoryIndex] = useState(null);

    const inputLower = input.toLowerCase();
    const filteredSuggestions = input.startsWith('/')
        ? suggestions
              .filter((suggestion) => suggestion.name.toLowerCase().startsWith(inputLower) || inputLower === '/')
              .slice(0, 6)
        : [];

    useEffect(() => {
        function handleMessage(event) {
            const data = event.data || {};

            if (data.action === 'setVisible') {
                setVisible(Boolean(data.visible));
                setInput(typeof data.prefill === 'string' ? data.prefill : '');
                setSelectedSuggestion(0);
                setHistoryIndex(null);
                return;
            }

            if (data.action === 'addMessage') {
                const message = normalizeMessage(data.message);

                if (!message) {
                    return;
                }

                setMessages((current) => [...current.slice(-79), message]);
                return;
            }

            if (data.action === 'setSuggestions') {
                const nextSuggestions = Array.isArray(data.suggestions)
                    ? data.suggestions.map(normalizeSuggestion).filter(Boolean)
                    : [];

                nextSuggestions.sort((left, right) => left.name.localeCompare(right.name));
                setSuggestions(nextSuggestions);
                return;
            }

            if (data.action === 'clearMessages') {
                setMessages([]);
            }
        }

        window.addEventListener('message', handleMessage);
        return () => window.removeEventListener('message', handleMessage);
    }, []);

    useEffect(() => {
        if (!visible || !inputRef.current) {
            return;
        }

        requestAnimationFrame(() => {
            inputRef.current.focus();
            const inputLength = inputRef.current.value.length;
            inputRef.current.setSelectionRange(inputLength, inputLength);
        });
    }, [visible]);

    useEffect(() => {
        if (selectedSuggestion >= filteredSuggestions.length) {
            setSelectedSuggestion(0);
        }
    }, [filteredSuggestions.length, selectedSuggestion]);

    function closeChat() {
        setVisible(false);
        setInput('');
        setHistoryIndex(null);
        postNui('close');
    }

    function submitMessage() {
        const message = input.trim();

        if (message === '') {
            closeChat();
            return;
        }

        setHistory((current) => [message, ...current.filter((entry) => entry !== message)].slice(0, 20));
        setInput('');
        setHistoryIndex(null);
        setVisible(false);
        postNui('submit', { message });
    }

    function applySuggestion(suggestion) {
        if (!suggestion) {
            return;
        }

        setInput(`${suggestion.name} `);
        setSelectedSuggestion(0);
        requestAnimationFrame(() => inputRef.current && inputRef.current.focus());
    }

    function handleKeyDown(event) {
        if (event.key === 'Escape') {
            event.preventDefault();
            closeChat();
            return;
        }

        if (event.key === 'Enter') {
            event.preventDefault();
            submitMessage();
            return;
        }

        if (event.key === 'Tab' && filteredSuggestions.length > 0) {
            event.preventDefault();
            applySuggestion(filteredSuggestions[selectedSuggestion]);
            return;
        }

        if (event.key === 'ArrowDown' && filteredSuggestions.length > 0) {
            event.preventDefault();
            setSelectedSuggestion((current) => (current + 1) % filteredSuggestions.length);
            return;
        }

        if (event.key === 'ArrowUp' && filteredSuggestions.length > 0) {
            event.preventDefault();
            setSelectedSuggestion((current) => (current - 1 + filteredSuggestions.length) % filteredSuggestions.length);
            return;
        }

        if (event.key === 'ArrowUp' && history.length > 0) {
            event.preventDefault();
            const nextIndex = historyIndex === null ? 0 : Math.min(historyIndex + 1, history.length - 1);
            setHistoryIndex(nextIndex);
            setInput(history[nextIndex]);
            return;
        }

        if (event.key === 'ArrowDown' && historyIndex !== null) {
            event.preventDefault();
            const nextIndex = historyIndex - 1;

            if (nextIndex < 0) {
                setHistoryIndex(null);
                setInput('');
                return;
            }

            setHistoryIndex(nextIndex);
            setInput(history[nextIndex]);
        }
    }

    return e(
        'div',
        { className: `chat-shell ${visible ? 'is-open' : 'is-passive'}` },
        e(
            'section',
            { className: 'chat-panel' },
            e(
                'header',
                { className: 'chat-header' },
                e('div', { className: 'chat-title' }, 'LSX / Comms'),
                e('div', { className: 'chat-status' }, visible ? 'Transmit ready' : 'Passive')
            ),
            e(
                'div',
                { className: 'message-feed' },
                messages.length === 0
                    ? e('div', { className: 'empty-feed' }, 'No radio traffic.')
                    : messages.map((message) =>
                          e(
                              'div',
                              { key: message.id, className: `chat-message ${message.variant}` },
                              e('span', { className: 'message-author' }, message.author),
                              e('span', { className: 'message-text' }, message.text)
                          )
                      )
            ),
            e(
                'div',
                { className: 'composer' },
                e(
                    'div',
                    { className: 'input-row' },
                    e('span', { className: 'prompt' }, '>'),
                    e('input', {
                        ref: inputRef,
                        className: 'chat-input',
                        value: input,
                        maxLength: 180,
                        spellCheck: false,
                        placeholder: 'Type message or /command',
                        onChange: (event) => {
                            setInput(event.target.value);
                            setHistoryIndex(null);
                            setSelectedSuggestion(0);
                        },
                        onKeyDown: handleKeyDown,
                    }),
                    e('span', { className: 'send-hint' }, 'Enter')
                ),
                e(
                    'div',
                    { className: `suggestions ${filteredSuggestions.length > 0 ? 'has-items' : ''}` },
                    filteredSuggestions.map((suggestion, index) =>
                        e(
                            'div',
                            {
                                key: suggestion.name,
                                className: `suggestion ${index === selectedSuggestion ? 'is-selected' : ''}`,
                                onMouseDown: (event) => {
                                    event.preventDefault();
                                    applySuggestion(suggestion);
                                },
                            },
                            e('span', { className: 'suggestion-name' }, suggestion.name),
                            e('span', { className: 'suggestion-help' }, suggestion.help)
                        )
                    )
                ),
                e(
                    'div',
                    { className: 'chat-footer' },
                    e('span', null, 'Tab autocomplete'),
                    e('span', null, 'Esc close')
                )
            )
        )
    );
}

ReactDOM.createRoot(document.getElementById('root')).render(e(App));
