// Shared data + icons for RideStory prototypes.
// Exposed on window so multiple babel scripts can share scope.

const RS_PLAYLISTS = [
  { id: 'bed',   name: 'Bedtime Classics',     count: 24, hue: 235, accentA: '#1f2a55', accentB: '#3a4d96', motif: 'moon'  },
  { id: 'morn',  name: 'Curious Mornings',     count: 18, hue: 28,  accentA: '#c25a2d', accentB: '#f3a35a', motif: 'sun'   },
  { id: 'ani',   name: 'Animal Tales',         count: 31, hue: 145, accentA: '#1f5238', accentB: '#3f8c5b', motif: 'leaf'  },
  { id: 'lull',  name: 'Lullabies',            count: 12, hue: 285, accentA: '#3a2456', accentB: '#7e5da6', motif: 'wave'  },
  { id: 'made',  name: 'Made-Up Worlds',       count: 22, hue: 335, accentA: '#7a2549', accentB: '#c46d8a', motif: 'rings' },
  { id: 'tiny',  name: 'Tiny Adventures',      count: 16, hue: 195, accentA: '#1f4a59', accentB: '#4a8aa3', motif: 'arc'   },
  { id: 'gard',  name: 'Songs From the Garden',count: 9,  hue: 95,  accentA: '#3d5a1f', accentB: '#7ea24b', motif: 'leaf'  },
  { id: 'feel',  name: 'Friends & Feelings',   count: 14, hue: 45,  accentA: '#7a5a1c', accentB: '#d4a44a', motif: 'sun'   },
];

const RS_RECENT = [
  { id: 'r1', title: 'The Three Little Foxes', playlistId: 'ani',  duration: '7:12' },
  { id: 'r2', title: 'Moon Cake Night',        playlistId: 'bed',  duration: '5:48' },
  { id: 'r3', title: 'Big Truck Day',          playlistId: 'tiny', duration: '4:30' },
  { id: 'r4', title: 'Hello, Star',            playlistId: 'lull', duration: '6:02' },
  { id: 'r5', title: 'A Garden Surprise',      playlistId: 'gard', duration: '3:55' },
];

const RS_FAVORITES = [
  { id: 'f1', title: 'Goodnight Owl',       playlistId: 'bed' },
  { id: 'f2', title: 'Pip the Penguin',     playlistId: 'ani' },
  { id: 'f3', title: 'The Big Carrot',      playlistId: 'gard'},
  { id: 'f4', title: 'When I Feel Wobbly',  playlistId: 'feel'},
];

const RS_CONTINUE = {
  title: 'Goodnight Owl',
  playlistName: 'Bedtime Classics',
  playlistId: 'bed',
  elapsed: '3:24',
  remaining: '4:32',
  progress: 0.43,
};

// Caption sample for player screen
const RS_CAPTION = [
  { t: 'And', active: false },
  { t: 'so', active: false },
  { t: 'the', active: false },
  { t: 'little', active: true },
  { t: 'owl', active: false },
  { t: 'fluffed', active: false },
  { t: 'her', active: false },
  { t: 'feathers', active: false },
  { t: 'and', active: false },
  { t: 'closed', active: false },
  { t: 'her', active: false },
  { t: 'eyes.', active: false },
];

// Stories per playlist (for playlist detail screen)
const RS_STORIES = {
  bed: [
    { id: 's-bed-1', title: 'Goodnight Owl',        duration: '7:48', listened: 0.43, starred: true  },
    { id: 's-bed-2', title: 'Moon Cake Night',      duration: '5:48', listened: 1.0,  starred: false },
    { id: 's-bed-3', title: 'The Sleepy Tugboat',   duration: '9:21', listened: 0,    starred: false },
    { id: 's-bed-4', title: 'Hush, Little Cricket', duration: '4:17', listened: 0,    starred: false },
    { id: 's-bed-5', title: 'Stars in the Window',  duration: '6:34', listened: 0.8,  starred: false },
    { id: 's-bed-6', title: 'One Last Story',       duration: '3:50', listened: 0,    starred: false },
  ],
  ani: [
    { id: 's-ani-1', title: 'The Three Little Foxes', duration: '7:12', listened: 1.0,  starred: false },
    { id: 's-ani-2', title: 'Pip the Penguin',        duration: '6:45', listened: 0,    starred: true  },
    { id: 's-ani-3', title: 'Mouse Finds a Hat',      duration: '4:02', listened: 0,    starred: false },
    { id: 's-ani-4', title: 'Brave Little Beetle',    duration: '5:50', listened: 0.25, starred: false },
    { id: 's-ani-5', title: 'Bear & The Bee',         duration: '8:11', listened: 0,    starred: false },
  ],
  tiny: [
    { id: 's-tiny-1', title: 'Big Truck Day',       duration: '4:30', listened: 1.0, starred: false },
    { id: 's-tiny-2', title: 'A Walk to the Pond',  duration: '5:14', listened: 0,   starred: false },
    { id: 's-tiny-3', title: 'The Lost Sneaker',    duration: '3:48', listened: 0,   starred: false },
    { id: 's-tiny-4', title: 'Helping at the Park', duration: '6:20', listened: 0,   starred: false },
  ],
  morn: [
    { id: 's-morn-1', title: 'Pancake Plans',     duration: '5:10', listened: 0, starred: false },
    { id: 's-morn-2', title: 'Why Is the Sky Blue?', duration: '4:35', listened: 0, starred: false },
    { id: 's-morn-3', title: 'Birds at the Window', duration: '6:08', listened: 0.5, starred: false },
  ],
};

// Fallback for playlists without an explicit list — generated on demand.
function rsStoriesFor(playlistId) {
  if (RS_STORIES[playlistId]) return RS_STORIES[playlistId];
  const pl = RS_PLAYLISTS.find(p => p.id === playlistId);
  const titles = ['First Story', 'A Quiet Adventure', 'Three Wishes', 'The Big Day', 'Tiny Surprise', 'Goodnight, You'];
  return titles.slice(0, Math.min(6, pl?.count || 6)).map((t, i) => ({
    id: `${playlistId}-${i}`,
    title: t,
    duration: `${3 + (i % 5)}:${(10 + i * 7) % 60}`.padStart(4, '0'),
    listened: i === 0 ? 0.3 : 0,
    starred: false,
  }));
}

// ────────── Icons (currentColor; sized via parent font-size or width/height) ──────────
const RSIcon = {
  play:  (p={}) => <svg viewBox="0 0 24 24" width={p.size||24} height={p.size||24} fill="currentColor"><path d="M7 4.5v15a1 1 0 0 0 1.55.83l11.5-7.5a1 1 0 0 0 0-1.66l-11.5-7.5A1 1 0 0 0 7 4.5z"/></svg>,
  pause: (p={}) => <svg viewBox="0 0 24 24" width={p.size||24} height={p.size||24} fill="currentColor"><rect x="6" y="4.5" width="4" height="15" rx="1.2"/><rect x="14" y="4.5" width="4" height="15" rx="1.2"/></svg>,
  back15:(p={}) => <svg viewBox="0 0 24 24" width={p.size||24} height={p.size||24} fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M3 9a9 9 0 1 1 1.5 5"/><polyline points="3 4 3 9 8 9"/><text x="12" y="16" fontSize="7" fill="currentColor" stroke="none" textAnchor="middle" fontFamily="-apple-system, system-ui" fontWeight="600">15</text></svg>,
  fwd15: (p={}) => <svg viewBox="0 0 24 24" width={p.size||24} height={p.size||24} fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M21 9a9 9 0 1 0-1.5 5"/><polyline points="21 4 21 9 16 9"/><text x="12" y="16" fontSize="7" fill="currentColor" stroke="none" textAnchor="middle" fontFamily="-apple-system, system-ui" fontWeight="600">15</text></svg>,
  star:  (p={}) => <svg viewBox="0 0 24 24" width={p.size||20} height={p.size||20} fill={p.filled?'currentColor':'none'} stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round"><path d="M12 3.5l2.6 5.5 6 .8-4.4 4.1 1.1 6-5.3-2.9-5.3 2.9 1.1-6L3.4 9.8l6-.8z"/></svg>,
  search:(p={}) => <svg viewBox="0 0 24 24" width={p.size||20} height={p.size||20} fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"><circle cx="11" cy="11" r="6.5"/><path d="m20 20-4-4"/></svg>,
  cc:    (p={}) => <svg viewBox="0 0 24 24" width={p.size||22} height={p.size||22} fill="none" stroke="currentColor" strokeWidth="1.6"><rect x="2.5" y="5" width="19" height="14" rx="3"/><path d="M10 10.5a2.5 2.5 0 0 0-4 0v3a2.5 2.5 0 0 0 4 0M18 10.5a2.5 2.5 0 0 0-4 0v3a2.5 2.5 0 0 0 4 0" strokeLinecap="round"/></svg>,
  gear:  (p={}) => <svg viewBox="0 0 24 24" width={p.size||20} height={p.size||20} fill="none" stroke="currentColor" strokeWidth="1.6"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1A1.7 1.7 0 0 0 9 19.4a1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1A1.7 1.7 0 0 0 4.6 9a1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></svg>,
  more:  (p={}) => <svg viewBox="0 0 24 24" width={p.size||20} height={p.size||20} fill="currentColor"><circle cx="5" cy="12" r="1.7"/><circle cx="12" cy="12" r="1.7"/><circle cx="19" cy="12" r="1.7"/></svg>,
  chevR: (p={}) => <svg viewBox="0 0 24 24" width={p.size||16} height={p.size||16} fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="9 5 16 12 9 19"/></svg>,
  chevD: (p={}) => <svg viewBox="0 0 24 24" width={p.size||16} height={p.size||16} fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="5 9 12 16 19 9"/></svg>,
  x:     (p={}) => <svg viewBox="0 0 24 24" width={p.size||20} height={p.size||20} fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"><path d="m6 6 12 12M18 6 6 18"/></svg>,
  car:   (p={}) => <svg viewBox="0 0 24 24" width={p.size||20} height={p.size||20} fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M3 13l1.5-5a3 3 0 0 1 2.9-2.2h9.2A3 3 0 0 1 19.5 8L21 13"/><path d="M3 13h18v4a1 1 0 0 1-1 1h-2v-2H6v2H4a1 1 0 0 1-1-1z"/><circle cx="7" cy="16" r=".9" fill="currentColor"/><circle cx="17" cy="16" r=".9" fill="currentColor"/></svg>,
  list:  (p={}) => <svg viewBox="0 0 24 24" width={p.size||20} height={p.size||20} fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"><path d="M4 6h16M4 12h16M4 18h16"/></svg>,
};

// ────────── Cover art generator — abstract motif per playlist ──────────
function RSCover({ playlist, size = 60, radius = 14 }) {
  const { accentA, accentB, motif } = playlist;
  const id = `cov-${playlist.id}-${String(size).replace('%','pct')}`;
  const isPercent = typeof size === 'string' && size.includes('%');
  const motifEl = (() => {
    switch (motif) {
      case 'moon':
        return (
          <>
            <circle cx="72" cy="28" r="14" fill="rgba(255,255,255,.85)"/>
            <circle cx="68" cy="26" r="13" fill={accentA}/>
          </>
        );
      case 'sun':
        return <circle cx="50" cy="70" r="38" fill="rgba(255,255,255,.55)"/>;
      case 'leaf':
        return (
          <>
            <path d="M20 80 Q 50 -10 80 80 Z" fill="rgba(255,255,255,.35)"/>
            <path d="M50 18 L 50 80" stroke="rgba(0,0,0,.18)" strokeWidth="1.5"/>
          </>
        );
      case 'wave':
        return (
          <>
            <path d="M0 60 Q 25 40 50 60 T 100 60 L 100 100 L 0 100 Z" fill="rgba(255,255,255,.3)"/>
            <path d="M0 75 Q 25 55 50 75 T 100 75 L 100 100 L 0 100 Z" fill="rgba(255,255,255,.25)"/>
          </>
        );
      case 'rings':
        return (
          <>
            <circle cx="50" cy="50" r="38" fill="none" stroke="rgba(255,255,255,.4)" strokeWidth="3"/>
            <circle cx="50" cy="50" r="24" fill="none" stroke="rgba(255,255,255,.45)" strokeWidth="3"/>
            <circle cx="50" cy="50" r="10" fill="rgba(255,255,255,.55)"/>
          </>
        );
      case 'arc':
        return (
          <>
            <path d="M-10 90 A 60 60 0 0 1 110 90" fill="none" stroke="rgba(255,255,255,.45)" strokeWidth="6"/>
            <path d="M10 90 A 40 40 0 0 1 90 90" fill="none" stroke="rgba(255,255,255,.35)" strokeWidth="5"/>
          </>
        );
      default:
        return null;
    }
  })();
  return (
    <svg viewBox="0 0 100 100" width={size} height={size} style={{ borderRadius: radius, display: 'block', flexShrink: 0, aspectRatio: isPercent ? '1 / 1' : undefined }} preserveAspectRatio="xMidYMid slice">
      <defs>
        <linearGradient id={id} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor={accentB}/>
          <stop offset="100%" stopColor={accentA}/>
        </linearGradient>
      </defs>
      <rect x="0" y="0" width="100" height="100" fill={`url(#${id})`}/>
      {motifEl}
    </svg>
  );
}

Object.assign(window, {
  RS_PLAYLISTS, RS_RECENT, RS_FAVORITES, RS_CONTINUE, RS_CAPTION,
  RS_STORIES, rsStoriesFor,
  RSIcon, RSCover,
});
