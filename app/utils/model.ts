const BATCH_SIZE = 1;
const ONNXOUTPUT = 84;

export const computeQuantizedEmbedding = (output: any, nSelected = 1) => {
  let quantizedEmbedding = Array(BATCH_SIZE)
    .fill(0)
    .map(() => Array(ONNXOUTPUT).fill(0));

  for (var i = 0; i < nSelected; i++) {
    for (var j = 0; j < ONNXOUTPUT; j++) {
      quantizedEmbedding[i][j] = parseInt(output[i * ONNXOUTPUT + j].toFixed());
    }
  }

  return quantizedEmbedding;
};
