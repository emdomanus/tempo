--!strict
--!optimize 2
--!native

local ComponentTypes = script.components
local DefTypes = require(script.def)
local ManagerTypes = script.managers
local ServiceTypes = script.services

local TaskRecordTypes = require(ComponentTypes.taskRecord)
local HeapManagerTypes = require(ManagerTypes.heapManager)
local PhaseManagerTypes = require(ManagerTypes.phaseManager)
local TempoServiceTypes = require(ServiceTypes.tempoService)

export type Clock = DefTypes.Clock
export type NativePhase = DefTypes.NativePhase
export type PhaseName<PhaseT> = DefTypes.PhaseName<PhaseT>
export type Phase<PhaseT> = DefTypes.Phase<PhaseT>
export type ScheduledCallback = DefTypes.ScheduledCallback
export type PhaseCallback = DefTypes.PhaseCallback
export type Options = DefTypes.Options
export type TaskKind = DefTypes.TaskKind

export type TaskRecord = TaskRecordTypes.TaskRecord
export type RecordPoolOwner = TaskRecordTypes.RecordPoolOwner

export type HeapManager = HeapManagerTypes.HeapManager
export type PhaseState = PhaseManagerTypes.PhaseState
export type PhaseManager = PhaseManagerTypes.PhaseManager

export type TempoHandle<PhaseT> = TempoServiceTypes.TempoHandle<PhaseT>

return {}
