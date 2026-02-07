import { useCallback, useEffect, useState } from 'react'
import './App.css'

type Status = 'idle' | 'running' | 'success' | 'error'

const STATUS_LABELS: Record<Status, string> = {
  idle: '待機',
  running: '実行中',
  success: '成功',
  error: 'エラー',
}

interface ApiStatus {
  status: Status
  lastRun: string | null
  message: string | null
}

const API_BASE = import.meta.env.VITE_API_BASE ?? '/api'

/** Format timestamp as original time + 8 hours, in JST format. */
function formatJST(isoString: string): string {
  const d = new Date(isoString)
  const adjusted = new Date(d.getTime() + 8 * 60 * 60 * 1000)
  const formatted = adjusted.toLocaleString('ja-JP', {
    timeZone: 'Asia/Tokyo',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  })
  return `${formatted} (JST)`
}

async function fetchStatus(): Promise<ApiStatus> {
  const res = await fetch(`${API_BASE}/status`)
  if (!res.ok) throw new Error('ステータスを取得できませんでした')
  return res.json()
}

async function startRun(): Promise<{ started: boolean; message: string }> {
  const res = await fetch(`${API_BASE}/run`, { method: 'POST' })
  if (!res.ok) throw new Error('実行を開始できませんでした')
  return res.json()
}

function App() {
  const [apiStatus, setApiStatus] = useState<ApiStatus | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const loadStatus = useCallback(async () => {
    try {
      setError(null)
      const data = await fetchStatus()
      setApiStatus(data)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'バックエンドに接続できません')
      setApiStatus(null)
    }
  }, [])

  useEffect(() => {
    loadStatus()
  }, [loadStatus])

  const isRunning = apiStatus?.status === 'running'
  useEffect(() => {
    const interval = setInterval(loadStatus, isRunning ? 2000 : 10000)
    return () => clearInterval(interval)
  }, [loadStatus, isRunning])

  const handleRun = async () => {
    setLoading(true)
    setError(null)
    try {
      const result = await startRun()
      if (result.started) {
        setApiStatus((prev) => (prev ? { ...prev, status: 'running', lastRun: new Date().toISOString(), message: null } : null))
        await loadStatus()
      } else {
        setError(result.message)
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : '開始に失敗しました')
    } finally {
      setLoading(false)
    }
  }

  const status = apiStatus?.status ?? 'idle'
  const canRun = status !== 'running' && !loading

  return (
    <div className={`app ${isRunning ? 'app-frozen' : ''}`}>
      <header className="app-header">
        <h1>Amazon Business Automation</h1>
      </header>

      <section className="control">
        <button
          type="button"
          className="run-button"
          onClick={handleRun}
          disabled={!canRun}
          aria-busy={loading || status === 'running'}
        >
          {status === 'running' ? '実行中…' : loading ? '開始中…' : '自動化を実行'}
        </button>
      </section>

      <section className="status-section">
        <h2>ステータス</h2>
        {error && <div className="status status-error">エラー: {error}</div>}
        {!error && apiStatus && (
          <div className={`status status-${status}`} role="status">
            <span className="status-badge">{STATUS_LABELS[status]}</span>
            {apiStatus.lastRun && (
              <span className="status-time">最終実行: {formatJST(apiStatus.lastRun)}</span>
            )}
            {apiStatus.message && status === 'error' && (
              <pre className="status-message">{apiStatus.message}</pre>
            )}
          </div>
        )}
        {!error && !apiStatus && <div className="status status-idle">バックエンドを待機中…</div>}
      </section>
    </div>
  )
}

export default App
