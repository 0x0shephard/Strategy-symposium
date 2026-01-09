import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabase'
import { useAuth } from '../contexts/AuthContext'

export default function GameEditor({ game, onClose }) {
  const { user } = useAuth()
  const [activeTab, setActiveTab] = useState('basic')
  const [saving, setSaving] = useState(false)

  // Basic Info State
  const [title, setTitle] = useState(game?.title || '')
  const [description, setDescription] = useState(game?.description || '')
  const [startingValuation, setStartingValuation] = useState(game?.starting_valuation || 320000000)
  const [targetValuation, setTargetValuation] = useState(game?.target_valuation || 1000000000)

  // Scenarios State
  const [scenarios, setScenarios] = useState([])
  const [selectedScenario, setSelectedScenario] = useState(null)

  // Options State
  const [options, setOptions] = useState([])

  useEffect(() => {
    if (game) {
      fetchScenarios()
    }
  }, [game])

  useEffect(() => {
    if (selectedScenario) {
      fetchOptions()
    }
  }, [selectedScenario])

  const fetchScenarios = async () => {
    try {
      const { data, error } = await supabase
        .from('scenarios')
        .select('*')
        .eq('game_id', game.id)
        .order('scenario_number')

      if (error) throw error
      setScenarios(data || [])
    } catch (error) {
      console.error('Error fetching scenarios:', error)
    }
  }

  const fetchOptions = async () => {
    try {
      const { data, error } = await supabase
        .from('options')
        .select('*')
        .eq('scenario_id', selectedScenario.id)
        .order('option_number')

      if (error) throw error

      // Ensure we have all 5 options
      const allOptions = []
      for (let i = 1; i <= 5; i++) {
        const existing = data?.find(opt => opt.option_number === i)
        allOptions.push(existing || {
          option_number: i,
          statement: '',
          rgm: 1.0,
          mre: 1.0,
          ues: 1.0,
          crq: 1.0,
          rga: 1.0,
          cem: 1.0
        })
      }
      setOptions(allOptions)
    } catch (error) {
      console.error('Error fetching options:', error)
    }
  }

  const handleSaveBasicInfo = async () => {
    try {
      setSaving(true)

      if (game) {
        // Update existing game
        const { error } = await supabase
          .from('games')
          .update({
            title,
            description,
            starting_valuation: startingValuation,
            target_valuation: targetValuation
          })
          .eq('id', game.id)

        if (error) throw error
      } else {
        // Create new game
        const { data, error } = await supabase
          .from('games')
          .insert({
            title,
            description,
            starting_valuation: startingValuation,
            target_valuation: targetValuation,
            created_by: user.id
          })
          .select()
          .single()

        if (error) throw error

        // Update game reference for continued editing
        game = data
      }

      alert('Game saved successfully!')
    } catch (error) {
      console.error('Error saving game:', error)
      alert('Failed to save game: ' + error.message)
    } finally {
      setSaving(false)
    }
  }

  const handleAddScenario = async () => {
    if (!game?.id) {
      alert('Please save basic info first!')
      setActiveTab('basic')
      return
    }

    const scenarioNumber = scenarios.length + 1
    const scenarioTitle = `Scenario ${scenarioNumber}`

    try {
      const { data, error } = await supabase
        .from('scenarios')
        .insert({
          game_id: game.id,
          scenario_number: scenarioNumber,
          title: scenarioTitle,
          description: '',
          duration_minutes: 10
        })
        .select()
        .single()

      if (error) throw error
      setScenarios([...scenarios, data])
    } catch (error) {
      console.error('Error adding scenario:', error)
      alert('Failed to add scenario: ' + error.message)
    }
  }

  const handleUpdateScenario = async (scenario, field, value) => {
    try {
      const { error } = await supabase
        .from('scenarios')
        .update({ [field]: value })
        .eq('id', scenario.id)

      if (error) throw error

      setScenarios(scenarios.map(s =>
        s.id === scenario.id ? { ...s, [field]: value } : s
      ))
    } catch (error) {
      console.error('Error updating scenario:', error)
    }
  }

  const handleDeleteScenario = async (scenarioId) => {
    if (!confirm('Delete this scenario?')) return

    try {
      const { error } = await supabase
        .from('scenarios')
        .delete()
        .eq('id', scenarioId)

      if (error) throw error
      setScenarios(scenarios.filter(s => s.id !== scenarioId))
      if (selectedScenario?.id === scenarioId) {
        setSelectedScenario(null)
      }
    } catch (error) {
      console.error('Error deleting scenario:', error)
      alert('Failed to delete scenario: ' + error.message)
    }
  }

  const handleSaveOptions = async () => {
    if (!selectedScenario?.id) {
      alert('Please select a scenario first!')
      return
    }

    try {
      setSaving(true)

      for (const option of options) {
        if (option.id) {
          // Update existing
          const { error } = await supabase
            .from('options')
            .update({
              statement: option.statement || '',
              rgm: parseFloat(option.rgm),
              mre: parseFloat(option.mre),
              ues: parseFloat(option.ues),
              crq: parseFloat(option.crq),
              rga: parseFloat(option.rga),
              cem: parseFloat(option.cem)
            })
            .eq('id', option.id)

          if (error) throw error
        } else {
          // Insert new
          const { error} = await supabase
            .from('options')
            .insert({
              scenario_id: selectedScenario.id,
              option_number: option.option_number,
              statement: option.statement || '',
              rgm: parseFloat(option.rgm),
              mre: parseFloat(option.mre),
              ues: parseFloat(option.ues),
              crq: parseFloat(option.crq),
              rga: parseFloat(option.rga),
              cem: parseFloat(option.cem)
            })

          if (error) throw error
        }
      }

      alert('Options saved successfully!')
      fetchOptions()
    } catch (error) {
      console.error('Error saving options:', error)
      alert('Failed to save options: ' + error.message)
    } finally {
      setSaving(false)
    }
  }

  const handleOptionChange = (optionIndex, field, value) => {
    const newOptions = [...options]
    newOptions[optionIndex] = {
      ...newOptions[optionIndex],
      [field]: value
    }
    setOptions(newOptions)
  }

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="glass-panel rounded-2xl w-full max-w-6xl max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="p-6 border-b border-white/10 flex items-center justify-between">
          <h2 className="text-2xl font-bold text-gradient">
            {game ? 'Edit Game' : 'Create New Game'}
          </h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-white transition-colors"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Tabs */}
        <div className="flex gap-2 px-6 pt-4 border-b border-white/10">
          <button
            onClick={() => setActiveTab('basic')}
            className={`px-4 py-2 rounded-t-lg transition-colors ${
              activeTab === 'basic'
                ? 'bg-gradient text-white'
                : 'text-gray-400 hover:text-white'
            }`}
          >
            Basic Info
          </button>
          <button
            onClick={() => setActiveTab('scenarios')}
            className={`px-4 py-2 rounded-t-lg transition-colors ${
              activeTab === 'scenarios'
                ? 'bg-gradient text-white'
                : 'text-gray-400 hover:text-white'
            }`}
          >
            Scenarios ({scenarios.length})
          </button>
          <button
            onClick={() => setActiveTab('options')}
            className={`px-4 py-2 rounded-t-lg transition-colors ${
              activeTab === 'options'
                ? 'bg-gradient text-white'
                : 'text-gray-400 hover:text-white'
            }`}
            disabled={!selectedScenario}
          >
            Options {selectedScenario ? `(${selectedScenario.title})` : ''}
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6">
          {activeTab === 'basic' && (
            <div className="space-y-4 max-w-2xl">
              <div>
                <label className="block text-sm font-medium mb-2">Game Title *</label>
                <input
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="e.g., Strategy Symposium R2"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium mb-2">Description</label>
                <textarea
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Brief description of the game..."
                  rows={3}
                  className="w-full"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-2">Starting Valuation ($)</label>
                  <input
                    type="number"
                    value={startingValuation}
                    onChange={(e) => setStartingValuation(parseFloat(e.target.value))}
                    placeholder="320000000"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">Target Valuation ($)</label>
                  <input
                    type="number"
                    value={targetValuation}
                    onChange={(e) => setTargetValuation(parseFloat(e.target.value))}
                    placeholder="1000000000"
                  />
                </div>
              </div>

              <button
                onClick={handleSaveBasicInfo}
                disabled={saving || !title}
                className="w-full bg-gradient text-white font-semibold py-3 px-6 rounded-lg hover:opacity-90 disabled:opacity-50 transition-all mt-4"
              >
                {saving ? 'Saving...' : 'Save Basic Info'}
              </button>
            </div>
          )}

          {activeTab === 'scenarios' && (
            <div className="space-y-4">
              <div className="flex justify-between items-center mb-4">
                <h3 className="text-xl font-bold">Scenarios</h3>
                <button
                  onClick={handleAddScenario}
                  className="px-4 py-2 bg-gradient text-white font-semibold rounded-lg hover:opacity-90 transition-all"
                >
                  + Add Scenario
                </button>
              </div>

              {scenarios.length === 0 ? (
                <div className="text-center py-12 text-gray-400">
                  No scenarios yet. Add your first scenario to get started.
                </div>
              ) : (
                <div className="space-y-3">
                  {scenarios.map((scenario) => (
                    <div
                      key={scenario.id}
                      className={`glass-panel rounded-lg p-4 cursor-pointer transition-all ${
                        selectedScenario?.id === scenario.id ? 'ring-2 ring-accent' : ''
                      }`}
                      onClick={() => setSelectedScenario(scenario)}
                    >
                      <div className="flex items-start gap-4">
                        <div className="flex-1 space-y-2">
                          <input
                            type="text"
                            value={scenario.title}
                            onChange={(e) => handleUpdateScenario(scenario, 'title', e.target.value)}
                            placeholder="Scenario Title"
                            className="w-full font-semibold"
                            onClick={(e) => e.stopPropagation()}
                          />
                          <textarea
                            value={scenario.description || ''}
                            onChange={(e) => handleUpdateScenario(scenario, 'description', e.target.value)}
                            placeholder="Description (optional)"
                            rows={2}
                            className="w-full text-sm"
                            onClick={(e) => e.stopPropagation()}
                          />
                          <div className="flex items-center gap-2">
                            <label className="text-sm text-gray-400">Duration:</label>
                            <input
                              type="number"
                              value={scenario.duration_minutes}
                              onChange={(e) => handleUpdateScenario(scenario, 'duration_minutes', parseInt(e.target.value))}
                              className="w-20 text-sm"
                              onClick={(e) => e.stopPropagation()}
                            />
                            <span className="text-sm text-gray-400">minutes</span>
                          </div>
                        </div>
                        <button
                          onClick={(e) => {
                            e.stopPropagation()
                            handleDeleteScenario(scenario.id)
                          }}
                          className="text-red-400 hover:text-red-300 transition-colors"
                        >
                          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                          </svg>
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}

              {selectedScenario && (
                <div className="mt-4 p-4 bg-blue-500/10 border border-blue-500/30 rounded-lg">
                  <p className="text-sm text-blue-400">
                    Selected: <strong>{selectedScenario.title}</strong> - Click the "Options" tab to configure its options
                  </p>
                </div>
              )}
            </div>
          )}

          {activeTab === 'options' && selectedScenario && (
            <div className="space-y-4">
              <h3 className="text-xl font-bold mb-4">
                Options for {selectedScenario.title}
              </h3>

              <div className="space-y-6">
                {options.map((option, idx) => (
                  <div key={idx} className="glass-panel rounded-lg p-4">
                    <h4 className="font-semibold mb-3">Option {option.option_number}</h4>

                    {/* Option Statement (what players see) */}
                    <div className="mb-4">
                      <label className="block text-sm font-medium text-gray-300 mb-2">
                        Option Statement <span className="text-accent">(Players will see this)</span>
                      </label>
                      <textarea
                        value={option.statement || ''}
                        onChange={(e) => handleOptionChange(idx, 'statement', e.target.value)}
                        placeholder="Enter the option description that players will see..."
                        rows="3"
                        className="w-full bg-white/5 border border-white/10 rounded-lg px-4 py-2 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-accent resize-none"
                      />
                    </div>

                    {/* Variables (hidden from players) */}
                    <div className="border-t border-white/10 pt-4">
                      <p className="text-xs text-gray-400 mb-3">Variables (hidden from players):</p>
                      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
                        {['rgm', 'mre', 'ues', 'crq', 'rga', 'cem'].map((field) => (
                          <div key={field}>
                            <label className="block text-xs font-medium text-gray-400 mb-1 uppercase">
                              {field}
                            </label>
                            <input
                              type="number"
                              step="0.01"
                              value={option[field]}
                              onChange={(e) => handleOptionChange(idx, field, e.target.value)}
                              className="w-full"
                            />
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              <button
                onClick={handleSaveOptions}
                disabled={saving}
                className="w-full bg-gradient text-white font-semibold py-3 px-6 rounded-lg hover:opacity-90 disabled:opacity-50 transition-all mt-4"
              >
                {saving ? 'Saving...' : 'Save All Options'}
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
