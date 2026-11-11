import React, {useEffect, useState} from 'react';
import {continueRender, delayRender, staticFile} from 'remotion';

/**
 * Cairo variable font, bundled in public/fonts so the render never depends on
 * whatever the CI runner happens to have installed. Arabic shaping is done by
 * Chromium's HarfBuzz, so a real Arabic-capable face is the only requirement.
 */
export const FontLoader: React.FC = () => {
  const [handle] = useState(() => delayRender('nabd-font'));
  useEffect(() => {
    const face = new FontFace('Cairo', `url(${staticFile('fonts/Cairo.ttf')})`, {
      weight: '200 1000',
      style: 'normal',
    });
    face
      .load()
      .then((loaded) => {
        (document.fonts as unknown as {add: (f: unknown) => void}).add(loaded);
        continueRender(handle);
      })
      .catch(() => continueRender(handle));
  }, [handle]);
  return null;
};

export const fontFamily = 'Cairo, system-ui, sans-serif';
