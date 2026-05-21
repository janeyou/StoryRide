// RideStory — three home variations + shared player.
// All variations are passed a `tweaks` object so a single Tweaks panel can drive them.

const { useState } = React;

// ──────────────────────────────────────────────────────────────
// Shared bits
// ──────────────────────────────────────────────────────────────
const findPlaylist = (id) => RS_PLAYLISTS.find(p => p.id === id);

// MiniPlayer — persistent now-playing bar across all variations
function MiniPlayer({ palette, onOpen, onTogglePlay, isPlaying = true }) {
  const cont = RS_CONTINUE;
  const pl = findPlaylist(cont.playlistId);
  return (
    <div
      onClick={onOpen}
      style={{
        position: 'absolute',
        left: 12, right: 12, bottom: 44,
        height: 64,
        borderRadius: 18,
        background: palette.miniBg,
        color: palette.miniFg,
        display: 'flex', alignItems: 'center', gap: 12,
        padding: '0 10px 0 10px',
        boxShadow: palette.miniShadow,
        backdropFilter: 'blur(20px) saturate(180%)',
        WebkitBackdropFilter: 'blur(20px) saturate(180%)',
        border: palette.miniBorder,
        zIndex: 40,
        cursor: 'pointer',
      }}
    >
      <RSCover playlist={pl} size={48} radius={11}/>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 15, fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{cont.title}</div>
        <div style={{ fontSize: 12, opacity: 0.7, marginTop: 1 }}>{pl.name} · {cont.remaining} left</div>
        {/* tiny progress underline */}
        <div style={{ marginTop: 4, height: 2, borderRadius: 1, background: palette.miniTrack, overflow: 'hidden' }}>
          <div style={{ width: `${cont.progress * 100}%`, height: '100%', background: palette.accent }}/>
        </div>
      </div>
      <button
        onClick={(e) => { e.stopPropagation(); onTogglePlay && onTogglePlay(); }}
        style={{
          width: 44, height: 44, borderRadius: 22,
          background: palette.accent, color: palette.accentFg,
          border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer', flexShrink: 0,
        }}
      >
        {isPlaying ? <RSIcon.pause size={20}/> : <RSIcon.play size={20}/>}
      </button>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// VARIATION A — Warm Storybook (light cream + coral)
// ──────────────────────────────────────────────────────────────
function HomeWarm({ tweaks, onPlay, onOpenPlayer, driverMode }) {
  const accent = tweaks.accent;
  const cont = RS_CONTINUE;
  const contPl = findPlaylist(cont.playlistId);
  const density = tweaks.density; // 'cozy' | 'normal' | 'compact'
  const tileSize = density === 'cozy' ? 168 : density === 'compact' ? 122 : 148;

  const palette = {
    bg: '#f6f1e8',
    bgInk: '#1e1810',
    ink: '#2a221a',
    inkSoft: '#5e544a',
    inkFaint: '#9a8f80',
    card: '#ffffff',
    chip: '#ece4d5',
    border: 'rgba(38,28,14,0.08)',
    accent,
    accentFg: '#fffaf1',
    miniBg: 'rgba(255,250,243,0.92)',
    miniFg: '#2a221a',
    miniBorder: '1px solid rgba(38,28,14,0.06)',
    miniShadow: '0 12px 28px rgba(50,30,10,0.18)',
    miniTrack: 'rgba(38,28,14,0.10)',
  };

  return (
    <div style={{ background: palette.bg, color: palette.ink, minHeight: '100%', paddingBottom: 140, fontFamily: 'ui-rounded, "SF Pro Rounded", -apple-system, system-ui' }}>
      {/* Header */}
      <div style={{ padding: '56px 20px 8px 20px', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
        <div>
          <div style={{ fontSize: 13, letterSpacing: 1.4, fontWeight: 600, color: palette.inkFaint, textTransform: 'uppercase' }}>Good morning</div>
          <div style={{ fontSize: 32, fontWeight: 700, marginTop: 4, letterSpacing: -0.5 }}>Ride & Story</div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button style={iconBtn(palette)}><RSIcon.search size={20}/></button>
          <button style={iconBtn(palette)}><RSIcon.gear size={20}/></button>
        </div>
      </div>

      {/* Continue hero */}
      <div style={{ padding: '14px 16px 0 16px' }}>
        <div
          onClick={onOpenPlayer}
          style={{
            position: 'relative',
            borderRadius: 22, overflow: 'hidden',
            background: `linear-gradient(135deg, ${contPl.accentB}, ${contPl.accentA})`,
            color: '#fff',
            padding: '18px 18px 16px 18px',
            minHeight: 140,
            cursor: 'pointer',
          }}
        >
          <div style={{ fontSize: 11, letterSpacing: 1.8, opacity: 0.85, fontWeight: 700 }}>PICK UP WHERE YOU LEFT OFF</div>
          <div style={{ fontSize: 26, fontWeight: 700, marginTop: 6, lineHeight: 1.12 }}>{cont.title}</div>
          <div style={{ fontSize: 14, opacity: 0.85, marginTop: 4 }}>{contPl.name} · {cont.remaining} left</div>
          {/* progress */}
          <div style={{ marginTop: 14, height: 4, borderRadius: 2, background: 'rgba(255,255,255,0.25)', overflow: 'hidden' }}>
            <div style={{ width: `${cont.progress * 100}%`, height: '100%', background: '#fff' }}/>
          </div>
          {/* big play */}
          <button
            onClick={(e) => { e.stopPropagation(); onPlay && onPlay(cont); }}
            style={{
              position: 'absolute', right: 14, bottom: 14,
              width: 54, height: 54, borderRadius: 27,
              background: '#fff', color: contPl.accentA,
              border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 6px 20px rgba(0,0,0,0.25)',
              cursor: 'pointer',
            }}
          >
            <RSIcon.play size={24}/>
          </button>
        </div>
      </div>

      {/* Favorites — starred quick-tap pills */}
      <SectionTitle palette={palette}>★ Favorites</SectionTitle>
      <div style={{ display: 'flex', gap: 8, overflowX: 'auto', padding: '0 16px 4px 16px', scrollbarWidth: 'none' }}>
        {RS_FAVORITES.map(f => {
          const pl = findPlaylist(f.playlistId);
          return (
            <div key={f.id} onClick={() => onPlay && onPlay(f)} style={{
              display: 'flex', alignItems: 'center', gap: 10,
              background: palette.card, padding: '8px 14px 8px 8px',
              borderRadius: 999, flexShrink: 0,
              boxShadow: '0 1px 2px rgba(40,20,0,0.05)',
              border: `1px solid ${palette.border}`,
              cursor: 'pointer',
            }}>
              <RSCover playlist={pl} size={32} radius={16}/>
              <div style={{ fontSize: 14, fontWeight: 600, color: palette.ink, whiteSpace: 'nowrap' }}>{f.title}</div>
            </div>
          );
        })}
      </div>

      {/* All Playlists */}
      <SectionTitle palette={palette} action="See all">All Playlists</SectionTitle>
      <PlaylistGrid
        playlists={RS_PLAYLISTS}
        layout={tweaks.layout}
        tileSize={tileSize}
        palette={palette}
        onPlay={onPlay}
        cardBg={palette.card}
        cardBorder={palette.border}
        textColor={palette.ink}
        subTextColor={palette.inkSoft}
      />

      {/* Recently played list */}
      <SectionTitle palette={palette}>Recently played</SectionTitle>
      <div style={{ padding: '0 16px' }}>
        {RS_RECENT.slice(0, 4).map((r, i) => {
          const pl = findPlaylist(r.playlistId);
          return (
            <div key={r.id} onClick={() => onPlay && onPlay(r)} style={{
              display: 'flex', alignItems: 'center', gap: 12,
              padding: '10px 8px',
              borderBottom: i < 3 ? `1px solid ${palette.border}` : 'none',
              cursor: 'pointer',
            }}>
              <RSCover playlist={pl} size={44} radius={10}/>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 15, fontWeight: 600 }}>{r.title}</div>
                <div style={{ fontSize: 12.5, color: palette.inkSoft, marginTop: 2 }}>{pl.name} · {r.duration}</div>
              </div>
              <button style={{
                width: 36, height: 36, borderRadius: 18, border: `1px solid ${palette.border}`,
                background: palette.card, color: palette.ink,
                display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
              }}>
                <RSIcon.play size={14}/>
              </button>
            </div>
          );
        })}
      </div>

      {tweaks.miniBar && <MiniPlayer palette={palette} onOpen={onOpenPlayer}/>}
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// VARIATION B — Refined Dark (original palette evolved, no swipe)
// ──────────────────────────────────────────────────────────────
function HomeDark({ tweaks, onPlay, onOpenPlayer }) {
  const accent = tweaks.accent;
  const cont = RS_CONTINUE;
  const contPl = findPlaylist(cont.playlistId);
  const density = tweaks.density;
  const tileSize = density === 'cozy' ? 168 : density === 'compact' ? 122 : 148;

  const palette = {
    bg: '#0e0f13',
    ink: '#ececec',
    inkSoft: '#c8c8c8',
    inkFaint: '#7a7a7a',
    card: '#16181e',
    chip: '#1c1f27',
    border: 'rgba(255,255,255,0.06)',
    accent,
    accentFg: '#0e0f13',
    miniBg: 'rgba(22,24,30,0.92)',
    miniFg: '#ececec',
    miniBorder: '1px solid rgba(255,255,255,0.06)',
    miniShadow: '0 12px 32px rgba(0,0,0,0.45)',
    miniTrack: 'rgba(255,255,255,0.10)',
  };

  return (
    <div style={{ background: palette.bg, color: palette.ink, minHeight: '100%', paddingBottom: 140, fontFamily: 'ui-rounded, "SF Pro Rounded", -apple-system, system-ui' }}>
      <div style={{ padding: '56px 20px 8px 20px', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
        <div>
          <div style={{ fontSize: 12.5, letterSpacing: 1.4, fontWeight: 600, color: palette.inkFaint, textTransform: 'uppercase' }}>Home</div>
          <div style={{ fontSize: 32, fontWeight: 600, marginTop: 4, color: palette.ink, letterSpacing: -0.4 }}>RideStory</div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button style={iconBtn(palette)}><RSIcon.search size={20}/></button>
          <button style={iconBtn(palette)}><RSIcon.gear size={20}/></button>
        </div>
      </div>

      {/* Continue card — flat, edge-to-edge feel */}
      <div style={{ padding: '14px 16px 0 16px' }}>
        <div
          onClick={onOpenPlayer}
          style={{
            position: 'relative',
            borderRadius: 18, overflow: 'hidden',
            background: palette.card,
            border: `1px solid ${palette.border}`,
            display: 'flex', alignItems: 'center', gap: 14,
            padding: 14,
            cursor: 'pointer',
          }}
        >
          <RSCover playlist={contPl} size={84} radius={14}/>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 11, letterSpacing: 1.6, fontWeight: 700, color: accent, textTransform: 'uppercase' }}>Continue</div>
            <div style={{ fontSize: 19, fontWeight: 600, marginTop: 4, lineHeight: 1.2 }}>{cont.title}</div>
            <div style={{ fontSize: 12.5, color: palette.inkFaint, marginTop: 2 }}>{contPl.name} · {cont.remaining}</div>
            <div style={{ marginTop: 10, height: 3, borderRadius: 2, background: 'rgba(255,255,255,0.10)', overflow: 'hidden' }}>
              <div style={{ width: `${cont.progress * 100}%`, height: '100%', background: accent }}/>
            </div>
          </div>
          <button
            onClick={(e) => { e.stopPropagation(); onPlay && onPlay(cont); }}
            style={{
              width: 52, height: 52, borderRadius: 26,
              background: accent, color: palette.accentFg,
              border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0, cursor: 'pointer',
            }}
          >
            <RSIcon.play size={22}/>
          </button>
        </div>
      </div>

      <SectionTitle palette={palette}>Favorites</SectionTitle>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, padding: '0 16px' }}>
        {RS_FAVORITES.map(f => {
          const pl = findPlaylist(f.playlistId);
          return (
            <div key={f.id} onClick={() => onPlay && onPlay(f)} style={{
              display: 'flex', alignItems: 'center', gap: 10,
              background: palette.card,
              padding: 8,
              borderRadius: 12,
              border: `1px solid ${palette.border}`,
              cursor: 'pointer',
            }}>
              <RSCover playlist={pl} size={44} radius={9}/>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{f.title}</div>
                <div style={{ fontSize: 11.5, color: accent, marginTop: 2, display: 'flex', alignItems: 'center', gap: 4 }}>
                  <RSIcon.star size={11} filled={true}/> favorite
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <SectionTitle palette={palette} action="All →">Playlists</SectionTitle>
      <PlaylistGrid
        playlists={RS_PLAYLISTS}
        layout={tweaks.layout}
        tileSize={tileSize}
        palette={palette}
        onPlay={onPlay}
        cardBg={palette.card}
        cardBorder={palette.border}
        textColor={palette.ink}
        subTextColor={palette.inkFaint}
      />

      <SectionTitle palette={palette}>Recently played</SectionTitle>
      <div style={{ padding: '0 16px' }}>
        {RS_RECENT.slice(0, 4).map((r, i) => {
          const pl = findPlaylist(r.playlistId);
          return (
            <div key={r.id} onClick={() => onPlay && onPlay(r)} style={{
              display: 'flex', alignItems: 'center', gap: 12,
              padding: '12px 4px',
              borderBottom: i < 3 ? `1px solid ${palette.border}` : 'none',
              cursor: 'pointer',
            }}>
              <RSCover playlist={pl} size={42} radius={9}/>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 15, fontWeight: 500 }}>{r.title}</div>
                <div style={{ fontSize: 12.5, color: palette.inkFaint, marginTop: 2 }}>{pl.name} · {r.duration}</div>
              </div>
              <button style={{
                width: 32, height: 32, borderRadius: 16, border: 'none',
                background: 'transparent', color: accent,
                display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
              }}>
                <RSIcon.play size={14}/>
              </button>
            </div>
          );
        })}
      </div>

      {tweaks.miniBar && <MiniPlayer palette={palette} onOpen={onOpenPlayer}/>}
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// VARIATION C — Glance Dial (driver-mode, huge tap targets)
// ──────────────────────────────────────────────────────────────
function HomeDial({ tweaks, onPlay, onOpenPlayer, onOpenPlaylist, onOpenAll }) {
  const accent = tweaks.accent;
  const cont = RS_CONTINUE;
  const contPl = findPlaylist(cont.playlistId);
  const [isPlaying, setIsPlaying] = useState(true);
  const density = tweaks.density;
  const tileSize = density === 'cozy' ? 184 : density === 'compact' ? 134 : 158;

  const palette = {
    bg: '#0a0a0c',
    ink: '#f5f1ea',
    inkSoft: '#cfc7b8',
    inkFaint: '#8a8270',
    card: '#15151a',
    chip: '#1f1f25',
    border: 'rgba(255,255,255,0.07)',
    accent,
    accentFg: '#0a0a0c',
    miniBg: 'rgba(20,18,16,0.9)',
    miniFg: '#f5f1ea',
    miniBorder: '1px solid rgba(255,255,255,0.07)',
    miniShadow: '0 12px 32px rgba(0,0,0,0.55)',
    miniTrack: 'rgba(255,255,255,0.10)',
  };

  return (
    <div style={{ background: palette.bg, color: palette.ink, minHeight: '100%', paddingBottom: 140, fontFamily: 'ui-rounded, "SF Pro Rounded", -apple-system, system-ui' }}>
      {/* Compact top header — driver doesn't need branding */}
      <div style={{ padding: '50px 18px 4px 18px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, color: accent }}>
          <RSIcon.car size={18}/>
          <div style={{ fontSize: 13, fontWeight: 700, letterSpacing: 1.3, textTransform: 'uppercase' }}>Driver mode</div>
        </div>
        <button style={{ ...iconBtn(palette), width: 40, height: 40 }}><RSIcon.gear size={18}/></button>
      </div>

      {/* Now-Playing dial — dominates top half */}
      <div style={{ padding: '8px 16px 0 16px' }}>
        <div
          onClick={onOpenPlayer}
          style={{
            position: 'relative',
            borderRadius: 28, overflow: 'hidden',
            background: `linear-gradient(160deg, ${contPl.accentB}, ${contPl.accentA} 70%, #000 130%)`,
            color: '#fff',
            padding: '20px 20px 22px 20px',
            minHeight: 220,
            cursor: 'pointer',
            boxShadow: `0 16px 36px ${contPl.accentA}55`,
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ fontSize: 11, letterSpacing: 2, opacity: 0.85, fontWeight: 700 }}>NOW PLAYING</div>
            <div style={{
              display: 'inline-flex', alignItems: 'center', gap: 4,
              padding: '4px 10px', borderRadius: 999,
              background: 'rgba(255,255,255,0.18)', fontSize: 11, fontWeight: 600,
            }}>
              <RSIcon.cc size={12}/> off
            </div>
          </div>
          <div style={{ fontSize: 30, fontWeight: 700, marginTop: 16, lineHeight: 1.08, letterSpacing: -0.5 }}>{cont.title}</div>
          <div style={{ fontSize: 15, opacity: 0.85, marginTop: 4 }}>{contPl.name}</div>
          {/* progress + times */}
          <div style={{ marginTop: 18, height: 4, borderRadius: 2, background: 'rgba(255,255,255,0.25)', overflow: 'hidden' }}>
            <div style={{ width: `${cont.progress * 100}%`, height: '100%', background: '#fff' }}/>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6, fontSize: 12, opacity: 0.8 }}>
            <span>{cont.elapsed}</span><span>-{cont.remaining}</span>
          </div>
          {/* giant control row */}
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 18 }}>
            <button onClick={(e) => e.stopPropagation()} style={dialBtn('rgba(255,255,255,0.16)','#fff', 56)}>
              <RSIcon.back15 size={26}/>
            </button>
            <button
              onClick={(e) => { e.stopPropagation(); setIsPlaying(!isPlaying); }}
              style={dialBtn('#fff', contPl.accentA, 78)}
            >
              {isPlaying ? <RSIcon.pause size={34}/> : <RSIcon.play size={34}/>}
            </button>
            <button onClick={(e) => e.stopPropagation()} style={dialBtn('rgba(255,255,255,0.16)','#fff', 56)}>
              <RSIcon.fwd15 size={26}/>
            </button>
          </div>
        </div>
      </div>

      {/* Pinned favorites — huge tap targets, thumb-reach band */}
      <SectionTitle palette={palette}>Favorites</SectionTitle>
      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {RS_FAVORITES.slice(0, 3).map(f => {
          const pl = findPlaylist(f.playlistId);
          return (
            <button key={f.id} onClick={() => onPlay && onPlay(f)} style={{
              display: 'flex', alignItems: 'center', gap: 12,
              background: palette.card, border: `1px solid ${palette.border}`,
              padding: '10px 14px 10px 10px', borderRadius: 16,
              color: palette.ink, cursor: 'pointer', textAlign: 'left', width: '100%',
              minHeight: 64,
            }}>
              <RSCover playlist={pl} size={44} radius={10}/>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 17, fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{f.title}</div>
                <div style={{ fontSize: 12.5, color: palette.inkFaint, marginTop: 2 }}>{pl.name}</div>
              </div>
              <div style={{
                width: 44, height: 44, borderRadius: 22,
                background: 'rgba(255,255,255,0.06)', color: accent,
                display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
              }}>
                <RSIcon.play size={18}/>
              </div>
            </button>
          );
        })}
      </div>

      <SectionTitle palette={palette} action="See all →" onAction={onOpenAll}>All playlists</SectionTitle>
      <PlaylistGrid
        playlists={RS_PLAYLISTS}
        layout={tweaks.layout}
        tileSize={tileSize}
        palette={palette}
        onPlay={onOpenPlaylist || onPlay}
        cardBg={palette.card}
        cardBorder={palette.border}
        textColor={palette.ink}
        subTextColor={palette.inkFaint}
        big
      />

      {tweaks.miniBar && <MiniPlayer palette={palette} onOpen={onOpenPlayer} isPlaying={isPlaying} onTogglePlay={() => setIsPlaying(!isPlaying)}/>}
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// Shared helpers
// ──────────────────────────────────────────────────────────────
function SectionTitle({ children, palette, action, onAction }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '22px 22px 10px 22px',
    }}>
      <div style={{ fontSize: 18, fontWeight: 700, letterSpacing: -0.2, color: palette.ink }}>{children}</div>
      {action && (
        <button onClick={onAction} style={{
          fontSize: 13, color: palette.accent, fontWeight: 600,
          background: 'transparent', border: 'none', cursor: onAction ? 'pointer' : 'default',
          padding: '4px 8px', borderRadius: 8, fontFamily: 'inherit',
        }}>{action}</button>
      )}
    </div>
  );
}

function iconBtn(palette) {
  return {
    width: 38, height: 38, borderRadius: 19,
    background: palette.chip, color: palette.ink,
    border: `1px solid ${palette.border}`,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    cursor: 'pointer',
  };
}

function dialBtn(bg, fg, size) {
  return {
    width: size, height: size, borderRadius: size / 2,
    background: bg, color: fg, border: 'none', cursor: 'pointer',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    boxShadow: bg === '#fff' ? '0 8px 24px rgba(0,0,0,0.25)' : 'none',
  };
}

// ──────────────────────────────────────────────────────────────
// PlaylistGrid — three layouts: grid / list / carousel
// ──────────────────────────────────────────────────────────────
function PlaylistGrid({
  playlists, layout, tileSize, palette, onPlay,
  cardBg, cardBorder, textColor, subTextColor, big,
}) {
  if (layout === 'list') {
    return (
      <div style={{ padding: '0 16px' }}>
        {playlists.map((pl, i) => (
          <div key={pl.id} onClick={() => onPlay && onPlay(pl)} style={{
            display: 'flex', alignItems: 'center', gap: 14,
            padding: '12px 6px',
            borderBottom: i < playlists.length - 1 ? `1px solid ${cardBorder}` : 'none',
            cursor: 'pointer',
          }}>
            <RSCover playlist={pl} size={56} radius={12}/>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 16, fontWeight: 600, color: textColor }}>{pl.name}</div>
              <div style={{ fontSize: 13, color: subTextColor, marginTop: 2 }}>{pl.count} stories</div>
            </div>
            <RSIcon.chevR size={16}/>
          </div>
        ))}
      </div>
    );
  }

  if (layout === 'carousel') {
    return (
      <div style={{ display: 'flex', gap: 12, overflowX: 'auto', padding: '0 16px 8px 16px', scrollbarWidth: 'none' }}>
        {playlists.map(pl => (
          <div key={pl.id} onClick={() => onPlay && onPlay(pl)} style={{
            flexShrink: 0, width: 132,
            cursor: 'pointer',
          }}>
            <RSCover playlist={pl} size={132} radius={16}/>
            <div style={{ fontSize: 14, fontWeight: 600, color: textColor, marginTop: 8, lineHeight: 1.2 }}>{pl.name}</div>
            <div style={{ fontSize: 12, color: subTextColor, marginTop: 2 }}>{pl.count} stories</div>
          </div>
        ))}
      </div>
    );
  }

  // grid (default)
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14,
      padding: '0 16px',
    }}>
      {playlists.map(pl => (
        <div key={pl.id} onClick={() => onPlay && onPlay(pl)} style={{
          background: cardBg,
          borderRadius: 16, padding: big ? 12 : 10,
          border: `1px solid ${cardBorder}`,
          cursor: 'pointer',
        }}>
          <RSCover playlist={pl} size="100%" radius={12}/>
          <div style={{ fontSize: big ? 16 : 14.5, fontWeight: 600, color: textColor, marginTop: 10, lineHeight: 1.2 }}>{pl.name}</div>
          <div style={{ fontSize: 12.5, color: subTextColor, marginTop: 3 }}>{pl.count} stories</div>
        </div>
      ))}
    </div>
  );
}

// Tweak the RSCover behavior so it can take "100%" as size and become a square block.
function RSCoverSquare({ playlist, radius = 12 }) {
  return (
    <div style={{ position: 'relative', width: '100%', paddingBottom: '100%' }}>
      <div style={{ position: 'absolute', inset: 0 }}>
        <RSCover playlist={playlist} size="100%" radius={radius}/>
      </div>
    </div>
  );
}

Object.assign(window, { HomeWarm, HomeDark, HomeDial, MiniPlayer, findPlaylist });
