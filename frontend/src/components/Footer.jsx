import React from 'react'

export default function Footer() {
  return (
    <footer className="bg-pitch-900 text-pitch-50 mt-16">
      <div className="max-w-7xl mx-auto px-4 py-8 text-sm flex flex-col md:flex-row justify-between gap-4">
        <div>
          <p className="font-semibold">Football Manufacturing, Export, Industry Intelligence &amp; E-Commerce Management System</p>
          <p className="text-pitch-100/70 mt-1">A university Database Management Systems lab project. Company data is labelled Verified, Estimated, or Synthetic — see the About page.</p>
        </div>
        <div className="text-pitch-100/70">
          Built with SQL Server · FastAPI · React
        </div>
      </div>
    </footer>
  )
}
