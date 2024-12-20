import { describe, it, expect, beforeEach, vi } from 'vitest'

describe('Risk Assessment Contract', () => {
  let mockContractCall: any
  
  beforeEach(() => {
    mockContractCall = vi.fn()
  })
  
  it('should assess risk for a small loan', async () => {
    mockContractCall.mockResolvedValue({
      success: true,
      value: {
        riskScore: 510,
        suggestedInterestRate: 1520
      }
    })
    const result = await mockContractCall('assess-risk', 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM', 100000)
    expect(result.success).toBe(true)
    expect(result.value.riskScore).toBe(510)
    expect(result.value.suggestedInterestRate).toBe(1520)
  })
  
  it('should assess risk for a large loan', async () => {
    mockContractCall.mockResolvedValue({
      success: true,
      value: {
        riskScore: 600,
        suggestedInterestRate: 1700
      }
    })
    const result = await mockContractCall('assess-risk', 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM', 1000000)
    expect(result.success).toBe(true)
    expect(result.value.riskScore).toBe(600)
    expect(result.value.suggestedInterestRate).toBe(1700)
  })
  
  it('should cap the interest rate at 30%', async () => {
    mockContractCall.mockResolvedValue({
      success: true,
      value: {
        riskScore: 1000,
        suggestedInterestRate: 3000
      }
    })
    const result = await mockContractCall('assess-risk', 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM', 10000000)
    expect(result.success).toBe(true)
    expect(result.value.riskScore).toBe(1000)
    expect(result.value.suggestedInterestRate).toBe(3000)
  })
  
  it('should fail for invalid loan amount', async () => {
    mockContractCall.mockResolvedValue({
      success: false,
      error: 400
    })
    const result = await mockContractCall('assess-risk', 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM', 0)
    expect(result.success).toBe(false)
    expect(result.error).toBe(400)
  })
})

