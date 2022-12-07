import React from "react";
import Image from "next/image";

export default function Footer() {
  return (
    <footer className="flex h-24 w-full items-center border-t">
      <a
        className="flex items-center mx-auto gap-2"
        href="https://vercel.com?utm_source=create-next-app&utm_medium=default-template&utm_campaign=create-next-app"
        target="_blank"
        rel="noopener noreferrer"
      >
        Made by Shubham Kanodia and Harsh Agrawal for
        <Image
          src="/ethindia-logo.svg"
          alt="ETHIndia Logo"
          width={110}
          height={25}
        />
      </a>
    </footer>
  );
}
