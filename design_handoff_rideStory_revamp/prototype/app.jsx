// RideStory — main entry.
// Variation C ("Glance Dial") is the primary direction the user picked.
// It gets four artboards showing the full flow: Home → All Playlists →
// Playlist Detail → Player. A & B remain as reference artboards in a
// separate section, smaller.

const { useState: useStateA, useEffect: useEffectA } = React;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "layout": "list",
  "density": "normal",
  "accent": "#ffd166",
  "captionSize": 36,
  "captionsDefault": false,
  "driverMode": false,
  "miniBar": true
}/*EDITMODE-END*/;

// ───────────────────────────────────────────────────────────────
// A multi-screen artboard for variation C. `startScreen` controls
// which screen the artboard mounts on, so we can show each screen
// of the flow side-by-side in the canvas.
// ───────────────────────────────────────────────────────────────
function DialFlowArtboard({ tweaks, startScreen = 'home', startPlaylistId = 'ani' }) {
  const [screen, setScreen] = useStateA(startScreen);
  const [activePlaylist, setActivePlaylist] = useStateA(
    RS_PLAYLISTS.find(p => p.id === startPlaylistId) || RS_PLAYLISTS[0]
  );
  const [captionsOpen, setCaptionsOpen] = useStateA(tweaks.captionsDefault);
  useEffectA(() => { setCaptionsOpen(tweaks.captionsDefault); }, [tweaks.captionsDefault]);

  const goHome = () => setScreen('home');
  const goAll = () => setScreen('all');
  const goPlaylist = (pl) => { setActivePlaylist(pl); setScreen('detail'); };
  const goPlayer = () => setScreen('player');

  const playerPalette = { bg: '#0a0a0c', ink: '#f5f1ea' };

  let inner;
  if (screen === 'home') {
    inner = (
      <HomeDial
        tweaks={tweaks}
        onPlay={goPlayer}
        onOpenPlayer={goPlayer}
        onOpenPlaylist={goPlaylist}
        onOpenAll={goAll}
      />
    );
  } else if (screen === 'all') {
    inner = (
      <AllPlaylistsDial
        tweaks={tweaks}
        onBack={goHome}
        onOpenPlaylist={goPlaylist}
        onOpenPlayer={goPlayer}
      />
    );
  } else if (screen === 'detail') {
    inner = (
      <PlaylistDetailDial
        playlist={activePlaylist}
        tweaks={tweaks}
        onBack={() => setScreen(startScreen === 'detail' ? 'all' : 'home')}
        onPlay={goPlayer}
        onOpenPlayer={goPlayer}
      />
    );
  } else {
    inner = (
      <Player
        palette={playerPalette}
        accent={tweaks.accent}
        captionsOpen={captionsOpen}
        captionSize={tweaks.captionSize}
        onToggleCaptions={() => setCaptionsOpen(v => !v)}
        onClose={() => setScreen(startScreen === 'player' ? 'home' : startScreen)}
      />
    );
  }

  return (
    <IOSDevice width={390} height={844} dark={true}>
      {inner}
    </IOSDevice>
  );
}

// Reference artboard for A & B (just the home screens).
function ReferenceArtboard({ kind, tweaks }) {
  const HomeComponent = { warm: HomeWarm, dark: HomeDark }[kind];
  const [screen, setScreen] = useStateA('home');
  const [captionsOpen, setCaptionsOpen] = useStateA(tweaks.captionsDefault);
  useEffectA(() => { setCaptionsOpen(tweaks.captionsDefault); }, [tweaks.captionsDefault]);

  const playerPalette = {
    warm: { bg: '#1a130c', ink: '#fff7e8' },
    dark: { bg: '#0e0f13', ink: '#ececec' },
  }[kind];

  return (
    <IOSDevice width={390} height={844} dark={kind !== 'warm'}>
      {screen === 'home' ? (
        <HomeComponent
          tweaks={tweaks}
          onPlay={() => setScreen('player')}
          onOpenPlayer={() => setScreen('player')}
        />
      ) : (
        <Player
          palette={playerPalette}
          accent={tweaks.accent}
          captionsOpen={captionsOpen}
          captionSize={tweaks.captionSize}
          onToggleCaptions={() => setCaptionsOpen(v => !v)}
          onClose={() => setScreen('home')}
        />
      )}
    </IOSDevice>
  );
}

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);

  return (
    <>
      <DesignCanvas>
        {/* ───── Primary: variation C, full flow ───── */}
        <DCSection
          id="dial-flow"
          title="C · Glance Dial — full flow"
          subtitle="Driver-first variation. Tap any artboard's expand icon to take it full-screen; tap covers / continue cards / 'See all' to walk the flow live."
        >
          <DCArtboard id="dial-home"   label="1 · Home"             width={390} height={844}>
            <DialFlowArtboard tweaks={t} startScreen="home"/>
          </DCArtboard>
          <DCArtboard id="dial-all"    label="2 · All Playlists"    width={390} height={844}>
            <DialFlowArtboard tweaks={t} startScreen="all"/>
          </DCArtboard>
          <DCArtboard id="dial-detail" label="3 · Playlist Detail"  width={390} height={844}>
            <DialFlowArtboard tweaks={t} startScreen="detail" startPlaylistId="ani"/>
          </DCArtboard>
          <DCArtboard id="dial-player" label="4 · Player (CC off)"  width={390} height={844}>
            <DialFlowArtboard tweaks={t} startScreen="player"/>
          </DCArtboard>
        </DCSection>

        {/* ───── Reference: A & B home screens ───── */}
        <DCSection
          id="reference"
          title="Reference · alternative directions"
          subtitle="A & B from the earlier round, kept for comparison. Same data, same Tweaks panel — open one in focus mode if you want to revisit a detail."
        >
          <DCArtboard id="warm" label="A · Warm Storybook" width={390} height={844}>
            <ReferenceArtboard kind="warm" tweaks={t}/>
          </DCArtboard>
          <DCArtboard id="dark" label="B · Refined Dark" width={390} height={844}>
            <ReferenceArtboard kind="dark" tweaks={t}/>
          </DCArtboard>
        </DCSection>

        {/* ───── Notes ───── */}
        <DCSection
          id="notes"
          title="What makes C the driving-friendly pick"
          subtitle="Open these stickies as a quick design rationale."
        >
          <DCPostIt>
            <b>One-glance now-playing</b><br/>
            Top half of Home is dominated by the current story with transport baked in — no need to dive into a player screen at a red light.
          </DCPostIt>
          <DCPostIt color="#d1f4d4">
            <b>Thumb-band favorites</b><br/>
            Three chunky favorite rows sit right under the now-playing tile — exactly where a one-handed thumb on a mounted phone naturally rests.
          </DCPostIt>
          <DCPostIt color="#ffe4b8">
            <b>No swipe maze</b><br/>
            The original's horizontal <code>TabView</code> hid playlists. C surfaces all of them on Home and gives a full "All playlists" grid one tap away.
          </DCPostIt>
          <DCPostIt color="#d6e8ff">
            <b>Captions opt-in</b><br/>
            Player opens to cover art only. A single CC pill reveals giant read-along when parked — never auto-blasted at the driver.
          </DCPostIt>
        </DCSection>
      </DesignCanvas>

      {/* Tweaks panel */}
      <TweaksPanel title="Tweaks">
        <TweakSection title="Playlist layout">
          <TweakRadio
            label="Layout"
            value={t.layout}
            options={[
              { value: 'grid',     label: 'Grid' },
              { value: 'list',     label: 'List' },
              { value: 'carousel', label: 'Reel' },
            ]}
            onChange={(v) => setTweak('layout', v)}
          />
          <TweakRadio
            label="Density"
            value={t.density}
            options={[
              { value: 'compact', label: 'Tight' },
              { value: 'normal',  label: 'Normal' },
              { value: 'cozy',    label: 'Cozy' },
            ]}
            onChange={(v) => setTweak('density', v)}
          />
        </TweakSection>

        <TweakSection title="Color">
          <TweakColor
            label="Accent"
            value={t.accent}
            options={['#e09b87', '#f5a25a', '#7ec4a0', '#9a8cd1', '#e07b7b', '#ffd166']}
            onChange={(v) => setTweak('accent', v)}
          />
        </TweakSection>

        <TweakSection title="Read-along (captions)">
          <TweakToggle
            label="Show by default in player"
            value={t.captionsDefault}
            onChange={(v) => setTweak('captionsDefault', v)}
          />
          <TweakSlider
            label="Caption size"
            value={t.captionSize}
            min={20} max={64} step={2}
            onChange={(v) => setTweak('captionSize', v)}
            unit="px"
          />
        </TweakSection>

        <TweakSection title="Driving">
          <TweakToggle
            label="Now-playing mini bar"
            value={t.miniBar}
            onChange={(v) => setTweak('miniBar', v)}
          />
        </TweakSection>
      </TweaksPanel>
    </>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
