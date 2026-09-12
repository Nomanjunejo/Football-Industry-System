import React, { useEffect, useState } from 'react'
import { getBatches, createInspection } from '../../services/resourceService'

const TESTS = [
  ['WeightTestPass', 'Weight Test'],
  ['CircumferenceTestPass', 'Circumference Test'],
  ['PressureTestPass', 'Pressure Test'],
  ['BounceTestPass', 'Bounce Test'],
  ['ShapeTestPass', 'Shape Test'],
  ['MaterialTestPass', 'Material Test'],
]

export default function QualityControl() {
  const [batches, setBatches] = useState([])
  const [selectedBatch, setSelectedBatch] = useState('')
  const [tests, setTests] = useState(Object.fromEntries(TESTS.map(([k]) => [k, true])))
  const [score, setScore] = useState(90)
  const [result, setResult] = useState('')
  const [error, setError] = useState('')

  useEffect(() => {
    getBatches({ status: 'Completed' }).then(setBatches)
  }, [])

  const submit = async (e) => {
    e.preventDefault()
    setError('')
    setResult('')
    try {
      const status = Object.values(tests).every(Boolean) && score >= 70 ? 'PASS' : 'FAIL'
      await createInspection({
        BatchID: Number(selectedBatch),
        ...tests,
        QualityScore: Number(score),
        Status: status,
      })
      setResult(`Inspection recorded: ${status}. ${status === 'PASS' ? 'This batch will now flow into sellable inventory automatically.' : 'This batch will NOT become sellable inventory.'}`)
    } catch (err) {
      setError(err.response?.data?.detail || 'Could not record inspection.')
    }
  }

  return (
    <div>
      <h1 className="text-2xl font-bold mb-1">Quality Control</h1>
      <p className="text-sm text-gray-500 mb-6">
        A batch only becomes sellable inventory once it is <strong>Completed</strong> AND has a
        <strong> PASS</strong> inspection recorded here.
      </p>

      <form onSubmit={submit} className="bg-white rounded-lg shadow p-6 max-w-xl space-y-4">
        <div>
          <label className="text-sm font-medium">Completed Batch</label>
          <select value={selectedBatch} onChange={(e) => setSelectedBatch(e.target.value)} required className="border rounded-md px-3 py-2 w-full mt-1 text-sm">
            <option value="">Select a completed batch...</option>
            {batches.map((b) => <option key={b.BatchID} value={b.BatchID}>Batch #{b.BatchID} — Product #{b.ProductID} ({b.Quantity} units)</option>)}
          </select>
        </div>

        <div className="grid grid-cols-2 gap-2">
          {TESTS.map(([key, label]) => (
            <label key={key} className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={tests[key]}
                onChange={(e) => setTests({ ...tests, [key]: e.target.checked })}
              />
              {label}
            </label>
          ))}
        </div>

        <div>
          <label className="text-sm font-medium">Quality Score (0-100)</label>
          <input type="number" min="0" max="100" value={score} onChange={(e) => setScore(e.target.value)} className="border rounded-md px-3 py-2 w-full mt-1 text-sm" />
        </div>

        {error && <p className="text-sm text-red-600">{error}</p>}
        {result && <p className="text-sm text-pitch-700 font-medium">{result}</p>}

        <button className="bg-pitch-700 text-white px-5 py-2.5 rounded-md text-sm font-medium">Record Inspection</button>
      </form>
    </div>
  )
}
