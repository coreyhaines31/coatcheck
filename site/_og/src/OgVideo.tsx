import {loadFont} from '@remotion/google-fonts/Inter';
import {AbsoluteFill, Img, staticFile} from 'remotion';
import {MenuBarScene} from './MenuBarScene';

// Inter stands in for SF Pro when rendering off a Mac.
loadFont('normal', {weights: ['500', '600', '700'], subsets: ['latin']});

export type OgVideoProps = {
  name: string;
  icon: string;
  headline: string;
  headlineAccent: string;
  sub: string;
  accent: string;
  accentInk: string;
  accentFill: string;
  field: [string, string, string, string];
};

export const FONT = '-apple-system, BlinkMacSystemFont, "SF Pro Display", Inter, system-ui, sans-serif';
export const INK = '#1d1d1f';
export const INK_2 = '#636368';

// The family shell: daylight color field, one glass card, brand and headline. Coat Check uses the wide arrangement:
// brand and headline across the top, and a full-width menu bar scene below, since the notch only reads in a whole menu bar.
export const OgVideo = (props: OgVideoProps) => {
  const blobs = [
    {size: 760, left: -220, top: -260},
    {size: 640, left: 720, top: -240},
    {size: 600, left: 380, top: 250},
    {size: 520, left: 740, top: 230},
  ];
  return (
    <AbsoluteFill style={{background: '#f5f6f8', color: INK, fontFamily: FONT, letterSpacing: '-0.012em', WebkitFontSmoothing: 'antialiased'}}>
      {blobs.map((b, i) => (
        <div
          key={i}
          style={{position: 'absolute', width: b.size, height: b.size, left: b.left, top: b.top, borderRadius: '50%', opacity: 0.85,
            background: `radial-gradient(circle, ${props.field[i]}, transparent 68%)`}}
        />
      ))}
      <div
        style={{position: 'absolute', inset: '44px 52px', borderRadius: 44, background: 'rgba(255,255,255,0.58)',
          boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.9), inset 0 -1px 0 rgba(0,0,0,0.04), 0 1px 2px rgba(55,30,15,0.05), 0 14px 40px rgba(55,30,15,0.10)'}}
      />
      <div style={{position: 'absolute', left: 100, right: 100, top: 80, display: 'flex', alignItems: 'center', justifyContent: 'space-between'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: 16, fontSize: 32, fontWeight: 600, letterSpacing: '-0.025em'}}>
          <Img src={staticFile(props.icon)} style={{width: 64, height: 64, filter: 'drop-shadow(0 8px 16px rgba(120,20,20,0.22))'}} />
          {props.name}
        </div>
        <div style={{fontSize: 24, color: INK_2, letterSpacing: '-0.015em'}}>{props.sub}</div>
      </div>
      <div style={{position: 'absolute', left: 100, right: 100, top: 168, fontSize: 56, lineHeight: 1.04, fontWeight: 700, letterSpacing: '-0.04em'}}>
        {props.headline}
        <br />
        <span style={{color: props.accent}}>{props.headlineAccent}</span>
      </div>
      <div style={{position: 'absolute', left: 100, top: 318, width: 1000, height: 236}}>
        <MenuBarScene accentInk={props.accentInk} accentFill={props.accentFill} />
      </div>
    </AbsoluteFill>
  );
};
