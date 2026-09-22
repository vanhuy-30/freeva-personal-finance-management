/** Never log query strings, headers or bodies: clients may submit auth tokens there by mistake. */
export function httpRequestSerializer(request: {
  id?: string | number;
  method?: string;
  url?: string;
  remoteAddress?: string;
}) {
  return {
    id: request.id,
    method: request.method,
    url: request.url?.split('?')[0],
    remoteAddress: request.remoteAddress,
  };
}
