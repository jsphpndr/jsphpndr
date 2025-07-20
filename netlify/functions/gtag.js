export const handler = async () => {
  const GA_ID = process.env.GA_TRACKING_ID;
  const res = await fetch(`https://www.googletagmanager.com/gtag/js?id=${GA_ID}`);

  if (!res.ok) {
    return {
      statusCode: 500,
      body: '// Failed to fetch gtag.js',
    };
  }

  const js = await res.text();

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/javascript',
      'Cache-Control': 'public, max-age=31536000, immutable', // 1 year
    },
    body: js,
  };
};
