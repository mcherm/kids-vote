# Favicon

The site's icon is a yellow ballot going into a blue ballot box. `web/favicon.svg` is the source; the other two
files are generated from it and committed, so there's still no build step for deploys.

| File                       | Used by                                                                 |
|----------------------------|-------------------------------------------------------------------------|
| `web/favicon.svg`          | Current browsers (linked from the `<head>` of each page)                |
| `web/favicon.ico`          | Older browsers and tools that request `/favicon.ico` (16, 32, 48 px)    |
| `web/apple-touch-icon.png` | iPhone/iPad "Add to Home Screen" and some link previews (180 × 180 px)  |

Each page's `<head>` has:

```html
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
```

## Regenerating after changing the SVG

Requires ImageMagick (`brew install imagemagick`). From the `web/` directory:

```sh
magick -background none -density 384 favicon.svg -define icon:auto-resize=48,32,16 favicon.ico
magick -background none -density 1536 favicon.svg -resize 150x150 -background "#e8d5ae" -gravity center -extent 180x180 -flatten -depth 8 -strip apple-touch-icon.png
```

- The Apple icon gets the site's paper-tan background (`#e8d5ae`) because iOS shows transparency as black. The
  padding (150 px icon on a 180 px square) keeps it from touching the rounded corners iOS adds.
- ImageMagick's built-in SVG renderer mishandles `rotate(angle cx cy)` transforms, so the SVG avoids transforms and
  uses explicit coordinates (the tilted ballot is a `<polygon>`). Keep it that way, or check the output carefully.
- Browsers cache favicons aggressively. After deploying a new one, use a hard refresh (⌘⇧R) or a private window.
