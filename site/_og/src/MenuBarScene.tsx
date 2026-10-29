import type {ReactNode} from 'react';
import {Easing, interpolate, interpolateColors, useCurrentFrame, useVideoConfig} from 'remotion';
import {INK, INK_2} from './OgVideo';

// A crowded MacBook menu bar: eight icons are jammed behind the notch. The hanger opens Coat Check's drawer and each
// hidden icon glides into a numbered ticket and the payoff lands. Then the tickets fade, the drawer folds and the icons
// fade back in behind the notch, so the loop has no seam.
const STANDARD = Easing.bezier(0.4, 0, 0.2, 1);
const IN_OUT = Easing.bezier(0.65, 0, 0.35, 1);
const OUT_EASE = Easing.bezier(0, 0, 0.2, 1);

const W = 1000;
const BAR = 40;
const NOTCH = {left: 410, width: 180};
const DRAWER = {left: 420, top: 54, pad: 16};
const TICKET = {w: 60, h: 86, gap: 8};
const GLYPH = 18;

const paths: Record<string, ReactNode> = {
  moon: <path d="M19.5 14.5A8 8 0 1 1 9.5 4.5a6.5 6.5 0 0 0 10 10z" />,
  disk: <><circle cx="12" cy="12" r="8" /><circle cx="12" cy="12" r="2" /></>,
  camera: <><rect x="3" y="7" width="13" height="10" rx="2" /><path d="M16 11l5-3v8l-5-3" /></>,
  note: <><path d="M9 17V6l10-2v11" /><circle cx="7" cy="17" r="2" /><circle cx="17" cy="15" r="2" /></>,
  cloud: <path d="M7 18h10a4 4 0 0 0 .5-8A6 6 0 0 0 6 11.5 3.3 3.3 0 0 0 7 18z" />,
  bolt: <path d="M13 3 5 14h6l-1 7 8-11h-6z" />,
  bubble: <path d="M4 5h16v11H10l-5 4v-4H4z" />,
  gauge: <><path d="M5 17a8 8 0 1 1 14 0" /><path d="M12 14l3.5-4" /></>,
  grid: <><rect x="4" y="4" width="7" height="7" rx="1.5" /><rect x="13" y="4" width="7" height="7" rx="1.5" /><rect x="4" y="13" width="7" height="7" rx="1.5" /><rect x="13" y="13" width="7" height="7" rx="1.5" /></>,
  clip: <><rect x="5" y="5" width="14" height="16" rx="2" /><path d="M9 3h6v4H9z" /></>,
  eye: <><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z" /><circle cx="12" cy="12" r="3" /></>,
  timer: <><circle cx="12" cy="13" r="8" /><path d="M12 13V9M10 2h4" /></>,
  mic: <><rect x="9" y="3" width="6" height="11" rx="3" /><path d="M5 11a7 7 0 0 0 14 0M12 18v3" /></>,
  wifi: <><path d="M2 9a15 15 0 0 1 20 0" /><path d="M5.5 12.5a10 10 0 0 1 13 0" /><path d="M9 16a5 5 0 0 1 6 0" /><circle cx="12" cy="19.5" r="1" /></>,
  hanger: <><path d="M10 6.8a2.3 2.3 0 1 1 3.4 2c-.7.4-1.4.9-1.4 1.8v.6" /><path d="M12 11.2 3.7 17c-.8.6-.4 1.8.6 1.8h15.4c1 0 1.4-1.2.6-1.8L12 11.2z" /></>,
};

const Glyph = ({name, size, color}: {name: string; size: number; color: string}) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" style={{display: 'block'}}>
    {paths[name]}
  </svg>
);

const HIDDEN = ['moon', 'disk', 'camera', 'note', 'cloud', 'bolt', 'bubble', 'gauge'];
const VISIBLE = ['mic', 'timer', 'eye', 'clip', 'grid'];
const ticketX = (i: number) => DRAWER.left + DRAWER.pad + i * (TICKET.w + TICKET.gap);
const TICKET_TOP = DRAWER.top + DRAWER.pad + 26;
// A ticket stub: rounded corners with a punched half-circle on each side at the perforation.
const PERF = 58;
const TICKET_PATH = (() => {
  const {w, h} = TICKET;
  const r = 7;
  const p = 5;
  return `M${r} 0.75 H${w - r} A${r - 0.75} ${r - 0.75} 0 0 1 ${w - 0.75} ${r} V${PERF - p} A${p} ${p} 0 0 0 ${w - 0.75} ${PERF + p} V${h - r}`
    + ` A${r - 0.75} ${r - 0.75} 0 0 1 ${w - r} ${h - 0.75} H${r} A${r - 0.75} ${r - 0.75} 0 0 1 0.75 ${h - r} V${PERF + p} A${p} ${p} 0 0 0 0.75 ${PERF - p} V${r}`
    + ` A${r - 0.75} ${r - 0.75} 0 0 1 ${r} 0.75 Z`;
})();

export const MenuBarScene = ({accentInk, accentFill}: {accentInk: string; accentFill: string}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = frame / fps;
  const ease = (input: number[], output: number[], easing: (n: number) => number) =>
    interpolate(t, input, output, {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing});

  // 0.45–0.75s hanger lit · 0.7–1.15s drawer opens · 1.1–2.67s icons glide in, 0.15s apart · 2.75–3.0s verdict in
  // hold to 4.5s · 4.5–4.84s verdict out · 4.55–4.95s tickets fade · 5.0–5.6s drawer folds · 5.1–5.81s icons return to the notch
  const lit = ease([0.45, 0.75], [0, 1], STANDARD) * (1 - ease([5.2, 5.7], [0, 1], STANDARD));
  const open = ease([0.7, 1.15], [0, 1], IN_OUT) * (1 - ease([5.0, 5.6], [0, 1], IN_OUT));
  const verdictIn = ease([2.78, 3.0], [0, 1], OUT_EASE);
  const shown = verdictIn * ease([4.5, 4.68], [1, 0], STANDARD);
  const waiting = 1 - ease([2.6, 2.78], [0, 1], STANDARD) + ease([4.66, 4.84], [0, 1], STANDARD);
  const unticket = ease([4.55, 4.95], [0, 1], STANDARD);

  const icons = HIDDEN.map((name, i) => {
    const start = 1.1 + i * 0.15;
    // Drop out of the notch first, then slide across, so no icon crosses the visible ones in the menu bar.
    const kx = ease([start, start + 0.62], [0, 1], IN_OUT);
    const ky = ease([start, start + 0.62], [0, 1], STANDARD);
    // The flying copy takes over from the notch copy on the frame it departs, where the two are identical.
    const flying = t < start ? 0 : 1 - unticket;
    const parked = t < start ? 1 : ease([5.1 + i * 0.03, 5.6 + i * 0.03], [0, 1], STANDARD);
    const landed = ease([start + 0.5, start + 0.75], [0, 1], OUT_EASE);
    const from = {x: NOTCH.left + 16 + i * 21, y: BAR / 2 - 2};
    const to = {x: ticketX(i) + TICKET.w / 2, y: TICKET_TOP + 26};
    return {name, i, landed, flying, parked, from, x: from.x + (to.x - from.x) * kx, y: from.y + (to.y - from.y) * ky, k: Math.max(kx, ky)};
  });

  return (
    <div
      style={{position: 'relative', width: W, height: '100%', borderRadius: 24, overflow: 'hidden',
        background: 'linear-gradient(165deg, #f4e9e1 0%, #efe3df 45%, #e4e6ee 100%)',
        boxShadow: '0 0 0 1px rgba(0,0,0,0.06), 0 2px 6px rgba(0,0,0,0.05), 0 16px 36px rgba(55,30,15,0.12)'}}
    >
      <div
        style={{position: 'absolute', left: 0, right: 0, top: 0, height: BAR, background: 'rgba(255,255,255,0.62)', borderBottom: '1px solid rgba(0,0,0,0.06)',
          display: 'flex', alignItems: 'center', gap: 18, padding: '0 24px', fontSize: 17, color: INK}}
      >
        <strong style={{fontWeight: 700}}>Finder</strong>
        {['File', 'Edit', 'View', 'Window'].map((m) => <span key={m}>{m}</span>)}
      </div>
      {VISIBLE.map((name, i) => (
        <div key={name} style={{position: 'absolute', left: 622 + i * 32 - GLYPH / 2, top: BAR / 2 - GLYPH / 2}}>
          <Glyph name={name} size={GLYPH} color={INK} />
        </div>
      ))}
      <div style={{position: 'absolute', left: 776, top: BAR / 2 - GLYPH / 2}}><Glyph name="wifi" size={GLYPH} color={INK} /></div>
      <div style={{position: 'absolute', left: 806, top: 13, width: 26, height: 13, borderRadius: 4, border: `1.8px solid ${INK}`, boxSizing: 'border-box', padding: 1.5}}>
        <div style={{width: '70%', height: '100%', borderRadius: 1.5, background: INK}} />
      </div>
      <div style={{position: 'absolute', left: 844, top: 4, width: 32, height: 32, borderRadius: 7, background: `rgba(0,0,0,${0.1 * lit})`}} />
      <div style={{position: 'absolute', left: 849, top: 9}}><Glyph name="hanger" size={22} color={INK} /></div>
      <div style={{position: 'absolute', right: 22, top: 0, height: BAR, display: 'flex', alignItems: 'center', fontSize: 17, color: INK}}>Fri 9:41 AM</div>
      <div style={{position: 'absolute', left: NOTCH.left, top: 0, width: NOTCH.width, height: 36, background: '#0b0b0c', borderRadius: '0 0 16px 16px'}} />

      <div style={{position: 'absolute', left: 32, top: 78}}>
        <div style={{position: 'absolute', opacity: waiting, whiteSpace: 'nowrap'}}>
          <div style={{fontSize: 44, fontWeight: 700, letterSpacing: '-0.035em', color: '#8e8e93'}}>8 icons hidden</div>
          <div style={{fontSize: 22, color: INK_2, marginTop: 6}}>behind the notch</div>
        </div>
        <div style={{position: 'absolute', opacity: shown, transform: `translateY(${(1 - verdictIn) * 8}px)`, whiteSpace: 'nowrap'}}>
          <div style={{fontSize: 44, fontWeight: 700, letterSpacing: '-0.035em', color: accentInk}}>8 icons checked</div>
          <div style={{fontSize: 22, color: INK_2, marginTop: 6}}>Each one a click away</div>
        </div>
      </div>

      <div
        style={{position: 'absolute', left: DRAWER.left, top: DRAWER.top, width: W - DRAWER.left - 12, height: 160, boxSizing: 'border-box', padding: DRAWER.pad, borderRadius: 16,
          background: 'rgba(252,251,250,0.94)', boxShadow: '0 0 0 1px rgba(0,0,0,0.07), 0 10px 28px rgba(55,30,15,0.14)',
          opacity: open, transform: `translateY(${(1 - open) * -10}px)`, transformOrigin: 'top right'}}
      >
        <div style={{fontSize: 15, fontWeight: 600, color: INK_2, lineHeight: '18px'}}>No room in the menu bar</div>
      </div>
      {icons.map(({i, landed}) => (
        <div
          key={i}
          style={{position: 'absolute', left: ticketX(i), top: TICKET_TOP, width: TICKET.w, height: TICKET.h, opacity: open * (0.45 + 0.55 * landed) * (1 - unticket)}}
        >
          <svg width={TICKET.w} height={TICKET.h} style={{position: 'absolute', inset: 0, overflow: 'visible'}}>
            <path
              d={TICKET_PATH}
              fill={interpolateColors(landed, [0, 1], ['rgba(251,243,234,0)', '#fbf3ea'])}
              stroke={interpolateColors(landed, [0, 1], ['rgba(0,0,0,0.10)', 'rgba(158,33,41,0.34)'])}
              strokeWidth={1.5}
            />
          </svg>
          <div style={{position: 'absolute', left: 10, right: 10, top: PERF - 0.75, borderTop: `1.5px dashed rgba(158,33,41,${0.35 * landed})`}} />
          <div
            style={{position: 'absolute', left: 0, right: 0, bottom: 7, textAlign: 'center', fontSize: 15, fontWeight: 700, color: accentFill,
              fontVariantNumeric: 'tabular-nums', opacity: landed, transform: `translateY(${(1 - landed) * 5}px)`}}
          >
            No.{i + 1}
          </div>
        </div>
      ))}
      {icons.map(({name, from, parked}) => (
        <div key={name} style={{position: 'absolute', left: from.x - GLYPH / 2, top: from.y - GLYPH / 2, opacity: parked}}>
          <Glyph name={name} size={GLYPH} color="#8a8a90" />
        </div>
      ))}
      {icons.map(({name, x, y, k, flying}) => {
        const size = GLYPH * (1 + 0.45 * k);
        return (
          <div key={name} style={{position: 'absolute', left: x - size / 2, top: y - size / 2, opacity: flying}}>
            <Glyph name={name} size={size} color={interpolateColors(k, [0, 1], ['#8a8a90', INK])} />
          </div>
        );
      })}
    </div>
  );
};
