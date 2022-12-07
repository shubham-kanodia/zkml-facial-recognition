import React from "react";
import dynamic from "next/dynamic";

const ReactJson = dynamic(() => import("react-json-view"), {
  ssr: false,
});

export default function ClassifyResult({
  prediction,
  proof,
}: {
  prediction: number;
  proof: any;
}) {
  console.log({ proof });

  return (
    <div className="my-8">
      <p className="text-xl mb-2">
        <b>Prediction</b>
      </p>
      <p className="text-lg mb-6">Person {prediction + 1}</p>
      <p className="text-xl mb-2">
        <b>Proof</b>
      </p>
      <div className="mx-auto text-left">
        <ReactJson
          src={proof}
          theme="monokai"
          displayObjectSize={false}
          displayDataTypes={false}
          style={{
            padding: "8px 0px",
            borderRadius: "4px",
          }}
        />
      </div>
    </div>
  );
}
