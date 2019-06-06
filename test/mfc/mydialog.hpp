#pragma once

// local
#include "resource.h"

// mfc
#include <afxwin.h>

//windows
#include <windows.h>

// std


class MyDialog final : public CDialog {
public:
	explicit MyDialog(CWnd* pParent = nullptr) : CDialog(IDD_DIALOG1, pParent) {
	}
	~MyDialog() = default;

protected:
	CButton c_buttontest;

	virtual void DoDataExchange(CDataExchange* pDX) override {
		CDialog::DoDataExchange(pDX);
		DDX_Control(pDX, IDC_BUTTONTEST, c_buttontest);
	}

	virtual BOOL OnInitDialog() override {
		const BOOL res = CDialog::OnInitDialog();
		if(res){
			c_buttontest.SetWindowTextW(L"Hello World!");
		}
		return res;
	}

	void OnBnClickedButtontest() {
		c_buttontest.SetWindowTextW(L"Hello Again!");
	}

	DECLARE_MESSAGE_MAP()
};

