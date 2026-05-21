// RideStory — Player + queue screen (shared between variations).
// Captions hidden by default; tap-to-reveal CC pill.

const { useState: useStateP } = React;

function Player({ palette, onClose, captionsOpen, onToggleCaptions, captionSize, accent }) {
  const cont = RS_CONTINUE;
  const pl = findPlaylist(cont.playlistId);
  const [isPlaying, setIsPlaying] = useStateP(true);
  const [tab, setTab] = useStateP('player'); // 'player' | 'queue'

  // Full-bleed gradient backdrop based on playlist
  return (
    <div style={{
      background: palette.bg, color: palette.ink,
      minHeight: '100%',
      fontFamily: 'ui-rounded, "SF Pro Rounded", -apple-system, system-ui',
      position: 'relative',
    }}>
      {/* gradient wash from playlist color */}
      <div style={{
        position: 'absolute', inset: 0,
        background: `linear-gradient(180deg, ${pl.accentA}cc 0%, ${pl.accentA}55 30%, transparent 60%)`,
        pointerEvents: 'none',
      }}/>

      {/* Top chrome */}
      <div style={{
        position: 'relative', zIndex: 2,
        padding: '54px 16px 0 16px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <button onClick={onClose} style={topChromeBtn(palette)}>
          <RSIcon.chevD size={20}/>
        </button>
        <div style={{ textAlign: 'center', flex: 1 }}>
          <div style={{ fontSize: 11, letterSpacing: 1.6, fontWeight: 700, opacity: 0.7 }}>PLAYING FROM</div>
          <div style={{ fontSize: 14, fontWeight: 600, marginTop: 2 }}>{pl.name}</div>
        </div>
        <button style={topChromeBtn(palette)}>
          <RSIcon.more size={20}/>
        </button>
      </div>

      {/* Cover or captions */}
      <div style={{ position: 'relative', zIndex: 2, padding: '24px 28px 0 28px' }}>
        {captionsOpen ? (
          <CaptionPanel palette={palette} captionSize={captionSize} accent={accent}/>
        ) : (
          <div style={{
            width: '100%', aspectRatio: '1 / 1', maxWidth: 320, margin: '0 auto',
            position: 'relative',
          }}>
            <RSCover playlist={pl} size="100%" radius={24}/>
            {/* faint star button */}
            <button style={{
              position: 'absolute', top: 14, right: 14,
              width: 40, height: 40, borderRadius: 20,
              background: 'rgba(0,0,0,0.35)',
              backdropFilter: 'blur(10px)', WebkitBackdropFilter: 'blur(10px)',
              border: '1px solid rgba(255,255,255,0.18)', color: accent,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              cursor: 'pointer',
            }}>
              <RSIcon.star size={18} filled={true}/>
            </button>
          </div>
        )}
      </div>

      {/* Title block */}
      <div style={{ position: 'relative', zIndex: 2, padding: '22px 28px 0 28px' }}>
        <div style={{ fontSize: 26, fontWeight: 700, lineHeight: 1.1, letterSpacing: -0.4 }}>{cont.title}</div>
        <div style={{ fontSize: 14, marginTop: 4, opacity: 0.7 }}>narrated · 8 min</div>
      </div>

      {/* Progress */}
      <div style={{ position: 'relative', zIndex: 2, padding: '24px 28px 0 28px' }}>
        <div style={{ height: 4, borderRadius: 2, background: 'rgba(255,255,255,0.15)', overflow: 'hidden' }}>
          <div style={{ width: `${cont.progress * 100}%`, height: '100%', background: accent }}/>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 7, fontSize: 12, opacity: 0.7 }}>
          <span>{cont.elapsed}</span><span>-{cont.remaining}</span>
        </div>
      </div>

      {/* Transport */}
      <div style={{
        position: 'relative', zIndex: 2,
        padding: '20px 28px 0 28px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <button style={dialBtnP('rgba(255,255,255,0.08)', palette.ink, 60)}>
          <RSIcon.back15 size={28}/>
        </button>
        <button
          onClick={() => setIsPlaying(!isPlaying)}
          style={dialBtnP(accent, palette.bg, 80)}
        >
          {isPlaying ? <RSIcon.pause size={34}/> : <RSIcon.play size={34}/>}
        </button>
        <button style={dialBtnP('rgba(255,255,255,0.08)', palette.ink, 60)}>
          <RSIcon.fwd15 size={28}/>
        </button>
      </div>

      {/* CC pill — tap to reveal captions */}
      <div style={{
        position: 'relative', zIndex: 2,
        marginTop: 24, display: 'flex', justifyContent: 'center',
      }}>
        <button
          onClick={onToggleCaptions}
          style={{
            display: 'inline-flex', alignItems: 'center', gap: 8,
            padding: '10px 16px', borderRadius: 999,
            background: captionsOpen ? accent : 'rgba(255,255,255,0.08)',
            color: captionsOpen ? palette.bg : palette.ink,
            border: 'none', cursor: 'pointer',
            fontSize: 14, fontWeight: 600,
            fontFamily: 'inherit',
          }}
        >
          <RSIcon.cc size={18}/>
          {captionsOpen ? 'Hide read-along' : 'Show read-along'}
        </button>
      </div>
    </div>
  );
}

function CaptionPanel({ palette, captionSize, accent }) {
  return (
    <div style={{
      width: '100%', aspectRatio: '1 / 1', maxWidth: 320, margin: '0 auto',
      borderRadius: 24,
      background: 'rgba(0,0,0,0.45)',
      border: '1px solid rgba(255,255,255,0.10)',
      backdropFilter: 'blur(20px) saturate(180%)',
      WebkitBackdropFilter: 'blur(20px) saturate(180%)',
      padding: 24,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <div style={{
        fontSize: captionSize, lineHeight: 1.25,
        fontFamily: 'ui-rounded, "SF Pro Rounded", -apple-system, system-ui',
        textAlign: 'center',
        textWrap: 'pretty',
      }}>
        {RS_CAPTION.map((w, i) => (
          <span key={i} style={{
            color: w.active ? accent : 'rgba(255,255,255,0.88)',
            fontWeight: w.active ? 700 : 400,
            marginRight: 6,
          }}>{w.t}</span>
        ))}
      </div>
    </div>
  );
}

function topChromeBtn(palette) {
  return {
    width: 40, height: 40, borderRadius: 20,
    background: 'rgba(255,255,255,0.08)', color: palette.ink,
    border: '1px solid rgba(255,255,255,0.10)',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    cursor: 'pointer',
  };
}

function dialBtnP(bg, fg, size) {
  return {
    width: size, height: size, borderRadius: size / 2,
    background: bg, color: fg, border: 'none', cursor: 'pointer',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    boxShadow: typeof bg === 'string' && bg.startsWith('#') && bg.length === 7 && bg !== '#000000'
      ? `0 8px 24px ${bg}55` : 'none',
  };
}

Object.assign(window, { Player, CaptionPanel });
