// RideStory Dial — supporting screens for the C variant:
//   • AllPlaylistsDial — full browse of every playlist
//   • PlaylistDetailDial — one playlist's stories with one-tap play
// Both share the C palette and idiom (big tap targets, glanceable type).

const { useState: useStateDS } = React;

const DIAL_PALETTE = {
  bg: '#0a0a0c',
  ink: '#f5f1ea',
  inkSoft: '#cfc7b8',
  inkFaint: '#8a8270',
  card: '#15151a',
  cardElev: '#1c1c22',
  chip: '#1f1f25',
  border: 'rgba(255,255,255,0.07)',
};

// ───────────────────────────────────────────────────────────────
// Top bar shared between sub-screens
// ───────────────────────────────────────────────────────────────
function DialTopBar({ onBack, title, accent, action }) {
  return (
    <div style={{
      padding: '50px 16px 8px 16px',
      display: 'flex', alignItems: 'center', gap: 12,
    }}>
      {onBack ? (
        <button onClick={onBack} style={{
          width: 44, height: 44, borderRadius: 22, flexShrink: 0,
          background: DIAL_PALETTE.card, color: DIAL_PALETTE.ink,
          border: `1px solid ${DIAL_PALETTE.border}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer',
        }}>
          <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
            <polyline points="15 5 8 12 15 19"/>
          </svg>
        </button>
      ) : null}
      <div style={{ flex: 1, minWidth: 0, color: DIAL_PALETTE.ink }}>
        <div style={{ fontSize: 11, letterSpacing: 1.6, fontWeight: 700, color: accent, textTransform: 'uppercase' }}>{title.label}</div>
        <div style={{ fontSize: 22, fontWeight: 700, lineHeight: 1.15, letterSpacing: -0.3, marginTop: 1 }}>{title.text}</div>
      </div>
      {action}
    </div>
  );
}

// ───────────────────────────────────────────────────────────────
// All Playlists — single screen, every playlist in big tappable cards
// ───────────────────────────────────────────────────────────────
function AllPlaylistsDial({ tweaks, onBack, onOpenPlaylist, onOpenPlayer }) {
  const accent = tweaks.accent;
  const layout = tweaks.layout;

  return (
    <div style={{
      background: DIAL_PALETTE.bg, color: DIAL_PALETTE.ink,
      minHeight: '100%', paddingBottom: 140,
      fontFamily: 'ui-rounded, "SF Pro Rounded", -apple-system, system-ui',
    }}>
      <DialTopBar
        onBack={onBack}
        accent={accent}
        title={{ label: 'Library', text: 'All playlists' }}
        action={
          <button style={{
            width: 44, height: 44, borderRadius: 22, flexShrink: 0,
            background: DIAL_PALETTE.card, color: DIAL_PALETTE.ink,
            border: `1px solid ${DIAL_PALETTE.border}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer',
          }}>
            <RSIcon.search size={18}/>
          </button>
        }
      />

      {/* Big stat row */}
      <div style={{
        padding: '14px 16px 4px 16px',
        display: 'flex', gap: 8,
      }}>
        <StatChip label={`${RS_PLAYLISTS.length} playlists`} accent={accent}/>
        <StatChip label={`${RS_PLAYLISTS.reduce((s, p) => s + p.count, 0)} stories`}/>
        <StatChip label="A → Z" />
      </div>

      <div style={{ padding: '12px 16px 0 16px' }}>
        {layout === 'list' ? (
          // List layout
          RS_PLAYLISTS.map((pl, i) => (
            <button key={pl.id} onClick={() => onOpenPlaylist(pl)} style={{
              display: 'flex', alignItems: 'center', gap: 14,
              padding: '12px 6px', width: '100%',
              borderBottom: i < RS_PLAYLISTS.length - 1 ? `1px solid ${DIAL_PALETTE.border}` : 'none',
              cursor: 'pointer', background: 'transparent', border: 'none',
              color: DIAL_PALETTE.ink, textAlign: 'left',
              borderRadius: 0,
            }}>
              <RSCover playlist={pl} size={56} radius={12}/>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 17, fontWeight: 600 }}>{pl.name}</div>
                <div style={{ fontSize: 13, color: DIAL_PALETTE.inkFaint, marginTop: 2 }}>{pl.count} stories</div>
              </div>
              <RSIcon.chevR size={16}/>
            </button>
          ))
        ) : (
          // Grid layout (default)
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
            {RS_PLAYLISTS.map(pl => (
              <button key={pl.id} onClick={() => onOpenPlaylist(pl)} style={{
                background: DIAL_PALETTE.card, border: `1px solid ${DIAL_PALETTE.border}`,
                borderRadius: 18, padding: 12, cursor: 'pointer',
                color: DIAL_PALETTE.ink, textAlign: 'left',
              }}>
                <RSCover playlist={pl} size="100%" radius={12}/>
                <div style={{ fontSize: 16, fontWeight: 600, marginTop: 10, lineHeight: 1.2 }}>{pl.name}</div>
                <div style={{ fontSize: 12.5, color: DIAL_PALETTE.inkFaint, marginTop: 3 }}>{pl.count} stories</div>
              </button>
            ))}
          </div>
        )}
      </div>

      {tweaks.miniBar && (
        <MiniPlayer
          palette={dialMiniPalette(accent)}
          onOpen={onOpenPlayer}
        />
      )}
    </div>
  );
}

// ───────────────────────────────────────────────────────────────
// Playlist Detail — one playlist's stories, with play-all + per-row play
// ───────────────────────────────────────────────────────────────
function PlaylistDetailDial({ playlist, tweaks, onBack, onPlay, onOpenPlayer }) {
  const accent = tweaks.accent;
  const stories = rsStoriesFor(playlist.id);
  const totalMin = stories.reduce((s, st) => {
    const [m, sec] = st.duration.split(':').map(Number);
    return s + m + sec / 60;
  }, 0);

  return (
    <div style={{
      background: DIAL_PALETTE.bg, color: DIAL_PALETTE.ink,
      minHeight: '100%', paddingBottom: 140,
      fontFamily: 'ui-rounded, "SF Pro Rounded", -apple-system, system-ui',
      position: 'relative',
    }}>
      {/* gradient header backdrop */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 360,
        background: `linear-gradient(180deg, ${playlist.accentA}cc 0%, ${playlist.accentA}55 30%, ${DIAL_PALETTE.bg} 78%)`,
        pointerEvents: 'none',
      }}/>

      <div style={{ position: 'relative', zIndex: 1 }}>
        <DialTopBar
          onBack={onBack}
          accent="rgba(255,255,255,0.85)"
          title={{ label: 'Playlist', text: '' }}
          action={
            <button style={{
              width: 44, height: 44, borderRadius: 22, flexShrink: 0,
              background: 'rgba(255,255,255,0.10)', color: DIAL_PALETTE.ink,
              border: '1px solid rgba(255,255,255,0.12)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              cursor: 'pointer',
            }}>
              <RSIcon.more size={18}/>
            </button>
          }
        />

        {/* Header: cover + meta */}
        <div style={{ padding: '8px 22px 0 22px', display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
          <div style={{ width: 168, aspectRatio: '1 / 1', position: 'relative' }}>
            <RSCover playlist={playlist} size="100%" radius={20}/>
          </div>
          <div style={{ fontSize: 28, fontWeight: 700, marginTop: 18, lineHeight: 1.1, letterSpacing: -0.4 }}>{playlist.name}</div>
          <div style={{ fontSize: 13.5, color: 'rgba(255,255,255,0.7)', marginTop: 4 }}>
            {playlist.count} stories · {Math.round(totalMin)} min total
          </div>
        </div>

        {/* Action row */}
        <div style={{ padding: '18px 22px 0 22px', display: 'flex', gap: 10 }}>
          <button
            onClick={() => onPlay(stories[0])}
            style={{
              flex: 1, height: 56, borderRadius: 28,
              background: accent, color: DIAL_PALETTE.bg,
              border: 'none', cursor: 'pointer',
              fontSize: 17, fontWeight: 700,
              fontFamily: 'inherit',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
              boxShadow: `0 8px 24px ${accent}55`,
            }}
          >
            <RSIcon.play size={20}/> Play all
          </button>
          <button style={{
            width: 56, height: 56, borderRadius: 28,
            background: DIAL_PALETTE.card, color: DIAL_PALETTE.ink,
            border: `1px solid ${DIAL_PALETTE.border}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer',
          }}>
            <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
              <polyline points="16 3 21 3 21 8"/>
              <polyline points="4 20 9 20 9 15"/>
              <path d="M21 3l-7 7"/>
              <path d="M3 21l7-7"/>
            </svg>
          </button>
          <button style={{
            width: 56, height: 56, borderRadius: 28,
            background: DIAL_PALETTE.card, color: accent,
            border: `1px solid ${DIAL_PALETTE.border}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer',
          }}>
            <RSIcon.star size={22}/>
          </button>
        </div>

        {/* Story list */}
        <div style={{ padding: '22px 16px 0 16px', display: 'flex', flexDirection: 'column', gap: 6 }}>
          {stories.map((s, i) => {
            const inProgress = s.listened > 0 && s.listened < 1;
            const done = s.listened >= 1;
            return (
              <button
                key={s.id}
                onClick={() => onPlay(s)}
                style={{
                  display: 'flex', alignItems: 'center', gap: 14,
                  background: DIAL_PALETTE.card,
                  padding: '12px 10px 12px 14px',
                  borderRadius: 16,
                  border: `1px solid ${DIAL_PALETTE.border}`,
                  cursor: 'pointer', textAlign: 'left',
                  color: DIAL_PALETTE.ink,
                  minHeight: 64,
                  width: '100%',
                }}
              >
                <div style={{
                  width: 28, textAlign: 'center', fontSize: 13,
                  color: done ? DIAL_PALETTE.inkFaint : DIAL_PALETTE.inkSoft,
                  fontWeight: 600, flexShrink: 0,
                }}>
                  {done ? (
                    <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke={accent} strokeWidth="2.3" strokeLinecap="round" strokeLinejoin="round" style={{ margin: '0 auto', display: 'block' }}>
                      <polyline points="4 12 10 18 20 6"/>
                    </svg>
                  ) : i + 1}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{
                    fontSize: 16, fontWeight: 600,
                    color: done ? DIAL_PALETTE.inkFaint : DIAL_PALETTE.ink,
                    whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                  }}>{s.title}</div>
                  <div style={{ fontSize: 12.5, color: DIAL_PALETTE.inkFaint, marginTop: 3, display: 'flex', alignItems: 'center', gap: 6 }}>
                    <span>{s.duration}</span>
                    {inProgress && (
                      <>
                        <span style={{ opacity: 0.5 }}>·</span>
                        <span style={{ color: accent }}>{Math.round(s.listened * 100)}% in</span>
                      </>
                    )}
                    {s.starred && (
                      <span style={{ color: accent, display: 'inline-flex', alignItems: 'center' }}>
                        <RSIcon.star size={12} filled={true}/>
                      </span>
                    )}
                  </div>
                </div>
                <div style={{
                  width: 44, height: 44, borderRadius: 22,
                  background: inProgress ? accent : 'rgba(255,255,255,0.06)',
                  color: inProgress ? DIAL_PALETTE.bg : accent,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0,
                }}>
                  <RSIcon.play size={16}/>
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {tweaks.miniBar && (
        <MiniPlayer
          palette={dialMiniPalette(accent)}
          onOpen={onOpenPlayer}
        />
      )}
    </div>
  );
}

function StatChip({ label, accent }) {
  return (
    <div style={{
      padding: '7px 12px', borderRadius: 999,
      background: accent ? `${accent}22` : DIAL_PALETTE.card,
      border: `1px solid ${accent ? `${accent}44` : DIAL_PALETTE.border}`,
      color: accent || DIAL_PALETTE.inkSoft,
      fontSize: 12.5, fontWeight: 600,
    }}>{label}</div>
  );
}

function dialMiniPalette(accent) {
  return {
    miniBg: 'rgba(20,18,16,0.92)',
    miniFg: DIAL_PALETTE.ink,
    miniBorder: `1px solid ${DIAL_PALETTE.border}`,
    miniShadow: '0 12px 32px rgba(0,0,0,0.55)',
    miniTrack: 'rgba(255,255,255,0.10)',
    accent,
    accentFg: DIAL_PALETTE.bg,
  };
}

Object.assign(window, {
  AllPlaylistsDial, PlaylistDetailDial, DIAL_PALETTE, dialMiniPalette,
});
