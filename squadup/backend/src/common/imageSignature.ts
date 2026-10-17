// Confirma pelo conteúdo do ficheiro que é mesmo JPEG, PNG ou WEBP.
// Os JPEG começam todos por FF D8 FF; o 4.º byte varia (E0, E1, DB, EE, ...) consoante o
// telemóvel ou a app que gerou a imagem, por isso não pode ser verificado.
export function isAllowedImageContent(buffer: Buffer): boolean {
  if (!buffer || buffer.length < 12) {
    return false;
  }

  const isJpeg = buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff;
  const isPng = buffer.subarray(0, 4).toString('hex') === '89504e47';
  const isWebp =
    buffer.subarray(0, 4).toString('ascii') === 'RIFF' &&
    buffer.subarray(8, 12).toString('ascii') === 'WEBP';

  return isJpeg || isPng || isWebp;
}
