export default function Home() {
  return (
    <main style={{
      minHeight: '100vh',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '34px',
    }}>
      <div style={{ maxWidth: '900px', width: '100%' }}>
        <h1 style={{
          fontSize: '2.5rem',
          marginBottom: '13px',
          background: 'linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
          backgroundClip: 'text',
          fontWeight: 700,
        }}>
          BlackRoad Infrastructure
        </h1>
        <p style={{
          fontSize: '1.1rem',
          color: '#999',
          marginBottom: '55px',
          lineHeight: 1.618,
        }}>
          Deployment automation, CI/CD workflows, Terraform modules, and infrastructure-as-code for the BlackRoad OS distributed network.
        </p>

        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
          gap: '21px',
          marginBottom: '55px',
        }}>
          <StatCard label="Deploy Scripts" value="94" desc="Automated pipelines" color="#FF1D6C" />
          <StatCard label="Setup Scripts" value="32" desc="Configuration automation" color="#F5A623" />
          <StatCard label="Terraform Modules" value="IaC" desc="Multi-cloud provisioning" color="#9C27B0" />
          <StatCard label="Fleet Devices" value="8" desc="Connected nodes" color="#2979FF" />
        </div>

        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
          gap: '21px',
          marginBottom: '55px',
        }}>
          <SectionCard
            title="Terraform"
            items={[
              'Cloudflare DNS & Pages modules',
              'DigitalOcean droplet provisioning',
              'Railway service orchestration',
              'Production & staging environments',
            ]}
          />
          <SectionCard
            title="CI / CD"
            items={[
              'Reusable GitHub Actions workflows',
              'Composite action templates',
              'Auto-deploy on push to main',
              'Multi-environment promotion',
            ]}
          />
          <SectionCard
            title="Docker"
            items={[
              'Multi-service compose stacks',
              'Optimized production images',
              'Health check integration',
              'Container orchestration',
            ]}
          />
          <SectionCard
            title="Operations"
            items={[
              'Fleet SSH management',
              'Tailscale mesh networking',
              'Monitoring & alerting',
              'Backup & disaster recovery',
            ]}
          />
        </div>

        <div style={{
          background: '#111',
          border: '1px solid #222',
          borderRadius: '13px',
          padding: '21px',
          marginBottom: '55px',
        }}>
          <h3 style={{
            color: '#F5A623',
            fontSize: '0.85rem',
            textTransform: 'uppercase',
            letterSpacing: '1px',
            marginBottom: '13px',
          }}>
            Network Topology
          </h3>
          <div style={{
            fontFamily: "'SF Mono', Monaco, Consolas, monospace",
            fontSize: '0.8rem',
            color: '#666',
            lineHeight: 1.8,
          }}>
            <div><span style={{color:'#FF1D6C'}}>alexandria</span> <span style={{color:'#444'}}>──</span> Mac host <span style={{color:'#444'}}>│</span> orchestrator</div>
            <div><span style={{color:'#F5A623'}}>cecilia</span> <span style={{color:'#444'}}>────</span> Pi 5 + Hailo-8 (26 TOPS) <span style={{color:'#444'}}>│</span> primary AI agent</div>
            <div><span style={{color:'#9C27B0'}}>lucidia</span> <span style={{color:'#444'}}>────</span> Pi 5 + Pironman + 1TB NVMe <span style={{color:'#444'}}>│</span> inference</div>
            <div><span style={{color:'#2979FF'}}>octavia</span> <span style={{color:'#444'}}>────</span> Pi 5 <span style={{color:'#444'}}>│</span> multi-arm processing</div>
            <div><span style={{color:'#4ade80'}}>alice</span> <span style={{color:'#444'}}>──────</span> Pi 4 <span style={{color:'#444'}}>│</span> worker node</div>
            <div><span style={{color:'#FF1D6C'}}>aria</span> <span style={{color:'#444'}}>───────</span> Pi 5 <span style={{color:'#444'}}>│</span> harmony protocols</div>
            <div><span style={{color:'#F5A623'}}>shellfish</span> <span style={{color:'#444'}}>───</span> DigitalOcean <span style={{color:'#444'}}>│</span> edge compute</div>
            <div><span style={{color:'#9C27B0'}}>infinity</span> <span style={{color:'#444'}}>────</span> DigitalOcean <span style={{color:'#444'}}>│</span> cloud oracle</div>
          </div>
        </div>

        <footer style={{
          textAlign: 'center',
          color: '#444',
          fontSize: '0.75rem',
          paddingTop: '21px',
          borderTop: '1px solid #1a1a1a',
        }}>
          &copy; 2025&ndash;2026 BlackRoad OS, Inc. All Rights Reserved.
        </footer>
      </div>
    </main>
  )
}

function StatCard({ label, value, desc, color }: { label: string; value: string; desc: string; color: string }) {
  return (
    <div style={{
      background: '#111',
      border: '1px solid #222',
      borderRadius: '13px',
      padding: '21px',
    }}>
      <h3 style={{
        color,
        fontSize: '0.8rem',
        textTransform: 'uppercase',
        letterSpacing: '1px',
        marginBottom: '8px',
      }}>
        {label}
      </h3>
      <div style={{ fontSize: '1.8rem', fontWeight: 700, color: '#fff', marginBottom: '4px' }}>
        {value}
      </div>
      <div style={{ color: '#666', fontSize: '0.85rem' }}>{desc}</div>
    </div>
  )
}

function SectionCard({ title, items }: { title: string; items: string[] }) {
  return (
    <div style={{
      background: '#111',
      border: '1px solid #222',
      borderRadius: '13px',
      padding: '21px',
    }}>
      <h3 style={{
        color: '#FF1D6C',
        fontSize: '0.9rem',
        textTransform: 'uppercase',
        letterSpacing: '1px',
        marginBottom: '13px',
      }}>
        {title}
      </h3>
      <ul style={{
        listStyle: 'none',
        padding: 0,
        margin: 0,
      }}>
        {items.map((item, i) => (
          <li key={i} style={{
            color: '#999',
            fontSize: '0.85rem',
            lineHeight: 1.618,
            paddingLeft: '13px',
            position: 'relative',
          }}>
            <span style={{
              position: 'absolute',
              left: 0,
              color: '#444',
            }}>
              ›
            </span>
            {item}
          </li>
        ))}
      </ul>
    </div>
  )
}
