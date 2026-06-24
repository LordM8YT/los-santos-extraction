const { useEffect, useState } = React;
const e = React.createElement;

const defaultRaid = {
    active: false,
    secondsLeft: 0,
    carryValueText: '$0',
    carryWeightText: '0 / 0',
};

const defaultProgress = {
    active: false,
    label: 'Working',
    percent: 0,
};

const defaultStatus = {
    active: false,
    health: 100,
    armor: 0,
    stamina: 100,
    armed: false,
    aiming: false,
    sprinting: false,
    firstPerson: false,
    heading: 0,
    cardinal: 'N',
    location: 'Unknown Sector',
    crossing: '',
    inVehicle: false,
    speed: 0,
    coords: { x: 0, y: 0, z: 0 },
    minimapVisible: false,
    minimapRangeMeters: 220,
    combatView: {
        helmetOverlay: false,
        crosshairMode: 'dynamic',
        forceFirstPerson: false,
    },
};

const defaultSettings = {
    minimapMode: 'vehicle',
    hudDensity: 'full',
    firstPersonMode: 'raid',
    crosshairMode: 'dynamic',
    helmetOverlay: 'on',
};

function clamp(value, min = 0, max = 100) {
    return Math.max(min, Math.min(max, Number(value) || 0));
}

function formatTime(seconds) {
    const safeSeconds = Math.max(0, Number(seconds) || 0);
    const mins = Math.floor(safeSeconds / 60);
    const secs = safeSeconds % 60;
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
}

function Meter({ label, value, variant }) {
    const safeValue = clamp(value);

    return e(
        'div',
        { className: 'bar-row' },
        e('span', { className: 'label' }, label),
        e('div', { className: 'meter' }, e('div', { className: `meter-fill ${variant || ''}`, style: { width: `${safeValue}%` } })),
        e('span', { className: 'bar-value' }, Math.floor(safeValue))
    );
}

function RaidBar({ raid, status }) {
    if (!raid.active) {
        return null;
    }

    return e(
        'div',
        { className: 'top-rig' },
        e(
            'section',
            { className: 'raid-bar' },
            e(
                'div',
                { className: 'raid-cell' },
                e('div', { className: 'eyebrow' }, 'Secured value'),
                e('span', { className: 'big-value' }, raid.carryValueText || '$0')
            ),
            e(
                'div',
                { className: 'raid-timer' },
                e('div', { className: 'eyebrow' }, 'MIA timer'),
                e('strong', null, formatTime(raid.secondsLeft))
            ),
            e(
                'div',
                { className: 'raid-cell right' },
                e('div', { className: 'eyebrow' }, 'Carry weight'),
                e('span', { className: 'big-value' }, raid.carryWeightText || '0 / 0')
            )
        ),
        e(
            'div',
            { className: 'compass' },
            e('span', { className: 'compass-rule' }),
            e('span', null, `${status.cardinal || 'N'} ${Math.floor(status.heading || 0).toString().padStart(3, '0')}`),
            e('span', { className: 'compass-rule' })
        )
    );
}

function VitalsPanel({ status }) {
    if (!status.active) {
        return null;
    }

    const location = status.crossing ? `${status.location} / ${status.crossing}` : status.location;

    return e(
        'section',
        { className: 'vitals-panel' },
        e(
            'div',
            { className: 'sector-line' },
            e('span', { className: 'sector-name' }, location || 'Unknown Sector'),
            e('span', { className: 'subtle' }, status.inVehicle ? 'Mobile' : 'On Foot')
        ),
        e(Meter, { label: 'Health', value: status.health }),
        e(Meter, { label: 'Armor', value: status.armor, variant: 'armor' }),
        e(Meter, { label: 'Stamina', value: status.stamina, variant: 'stamina' })
    );
}

function ScannerPanel({ status }) {
    if (!status.active || !status.minimapVisible) {
        return null;
    }

    const coords = status.coords || {};

    return e(
        'section',
        { className: 'scanner-panel' },
        e(
            'div',
            { className: 'scanner-head' },
            e('span', null, 'GTA GPS Link'),
            e('strong', null, `${status.cardinal || 'N'} ${Math.floor(status.heading || 0).toString().padStart(3, '0')}`)
        ),
        e(
            'div',
            { className: 'scanner-foot' },
            e('span', null, `${Math.floor(status.speed || 0)} km/h`),
            e('span', null, `${coords.x || 0}, ${coords.y || 0}`),
            e('span', null, 'Native map')
        )
    );
}

function ProgressPanel({ progress }) {
    if (!progress.active) {
        return null;
    }

    const percent = clamp(progress.percent);

    return e(
        'section',
        { className: 'progress-panel' },
        e(
            'div',
            { className: 'progress-head' },
            e('span', { className: 'progress-title' }, progress.label || 'Working'),
            e('span', { className: 'progress-percent' }, `${Math.floor(percent)}%`)
        ),
        e('div', { className: 'progress-track' }, e('div', { className: 'progress-fill', style: { width: `${percent}%` } })),
        e('div', { className: 'progress-foot subtle' }, 'Backspace cancels')
    );
}

function HintPanel({ text }) {
    if (!text) {
        return null;
    }

    return e('section', { className: 'hint-panel' }, text);
}

function ToastStack({ toasts }) {
    return e(
        'section',
        { className: 'toast-stack' },
        toasts.map((toast) =>
            e(
                'div',
                { key: toast.id, className: `toast ${toast.variant || 'info'}` },
                e('div', { className: 'toast-title' }, toast.variant || 'info'),
                e('div', { className: 'toast-text' }, toast.message)
            )
        )
    );
}

function ProfilePanel({ profile }) {
    if (!profile.visible) {
        return null;
    }

    return e(
        'section',
        { className: 'profile-panel' },
        e('h2', null, profile.title || 'Extraction Profile'),
        (profile.lines || []).map((line, index) => e('p', { key: `${line}-${index}` }, line))
    );
}

function HelmetOverlay({ status }) {
    const combatView = status.combatView || {};

    if (!status.active || !combatView.helmetOverlay) {
        return null;
    }

    return e(
        'section',
        { className: 'helmet-overlay', 'aria-hidden': 'true' },
        e('span', { className: 'helmet-glass helmet-glass-left' }),
        e('span', { className: 'helmet-glass helmet-glass-right' }),
        e('span', { className: 'helmet-noise' }),
        e('span', { className: 'helmet-scanline' })
    );
}

function CombatReticle({ status }) {
    const combatView = status.combatView || {};

    if (!status.active || combatView.crosshairMode === 'off' || status.inVehicle || !status.armed) {
        return null;
    }

    const className = [
        'combat-reticle',
        status.aiming ? 'is-aiming' : '',
        status.sprinting ? 'is-sprinting' : '',
        status.firstPerson ? 'is-first-person' : '',
    ].filter(Boolean).join(' ');

    return e(
        'section',
        { className, 'aria-hidden': 'true' },
        e('span', { className: 'reticle-dot' }),
        e('span', { className: 'reticle-line reticle-line-top' }),
        e('span', { className: 'reticle-line reticle-line-right' }),
        e('span', { className: 'reticle-line reticle-line-bottom' }),
        e('span', { className: 'reticle-line reticle-line-left' })
    );
}

function App() {
    const [raid, setRaid] = useState(defaultRaid);
    const [progress, setProgress] = useState(defaultProgress);
    const [hint, setHint] = useState('');
    const [status, setStatus] = useState(defaultStatus);
    const [settings, setSettings] = useState(defaultSettings);
    const [toasts, setToasts] = useState([]);
    const [profile, setProfile] = useState({ visible: false, title: '', lines: [] });

    const hasVisibleHud = raid.active || progress.active || hint || status.active || toasts.length > 0 || profile.visible;

    useEffect(() => {
        document.documentElement.classList.toggle('hud-closed', !hasVisibleHud);
    }, [hasVisibleHud]);

    useEffect(() => {
        document.documentElement.classList.toggle('hud-minimal', settings.hudDensity === 'minimal');
        document.documentElement.dataset.minimapMode = settings.minimapMode || 'vehicle';
    }, [settings]);

    useEffect(() => {
        function handleMessage(event) {
            const { action, payload = {} } = event.data || {};

            if (action === 'boot') {
                return;
            }

            if (action === 'settings') {
                setSettings((current) => ({ ...current, ...payload }));
                return;
            }

            if (action === 'status') {
                setStatus((current) => ({ ...current, ...payload }));
                return;
            }

            if (action === 'raid') {
                setRaid((current) => ({ ...current, ...payload }));
                return;
            }

            if (action === 'progress') {
                setProgress((current) => ({ ...current, ...payload }));
                return;
            }

            if (action === 'hint') {
                setHint(payload.text || '');
                return;
            }

            if (action === 'notify' && payload.message) {
                const id = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
                setToasts((current) => [{ id, message: payload.message, variant: payload.variant || 'info' }, ...current].slice(0, 5));

                window.setTimeout(() => {
                    setToasts((current) => current.filter((toast) => toast.id !== id));
                }, payload.duration || 4800);
                return;
            }

            if (action === 'profile') {
                setProfile({
                    visible: true,
                    title: payload.title || 'Extraction Profile',
                    lines: Array.isArray(payload.lines) ? payload.lines : [],
                });

                window.setTimeout(() => {
                    setProfile((current) => ({ ...current, visible: false }));
                }, payload.duration || 15000);
            }
        }

        window.addEventListener('message', handleMessage);
        return () => window.removeEventListener('message', handleMessage);
    }, []);

    return e(
        'main',
        { className: 'hud' },
        e(HelmetOverlay, { status }),
        e(CombatReticle, { status }),
        e(RaidBar, { raid, status }),
        e('div', { className: 'bottom-left' }, e(ScannerPanel, { status }), e(VitalsPanel, { status })),
        e(ProgressPanel, { progress }),
        e(HintPanel, { text: hint }),
        e(ProfilePanel, { profile }),
        e(ToastStack, { toasts })
    );
}

ReactDOM.createRoot(document.getElementById('root')).render(e(App));
